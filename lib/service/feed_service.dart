//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:isolate';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/feed_api.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/iterable_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/graphql/clients/indexer_client.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class FeedService {
  ValueNotifier<int> get unviewedCount;

  ValueNotifier<bool> get hasFeed;

  Future checkNewFeeds();

  Future refreshFollowings(List<String> artistIds);

  Future<AppFeedData> fetchFeeds(
    FeedNext? next, {
    List<String> ignoredTokenIds,
  });

  Future<List<AssetToken>> fetchTokensByIndexerID(List<String> indexerIDs);

  Future refreshJWTToken(String jwtToken);
}

class AppFeedData {
  List<FeedEvent> events;
  List<AssetToken> tokens;
  FeedNext? next;
  List<String> missingTokenIDs;

  AppFeedData({
    required this.events,
    required this.tokens,
    required this.next,
    required this.missingTokenIDs,
  });

  AppFeedData insert(AppFeedData data) {
    final events = this.events + data.events;
    events.sort(((a, b) => a.timestamp.isBefore(b.timestamp) ? 1 : -1));

    final tokens = this.tokens + data.tokens;
    final missingTokenIDs = this.missingTokenIDs + data.missingTokenIDs;
    return AppFeedData(
      events: events,
      tokens: tokens,
      next: data.next,
      missingTokenIDs: missingTokenIDs,
    );
  }

  AppFeedData insertTokens(List<AssetToken> tokens) {
    final tokenIDs = tokens.map((e) => e.id).toSet();
    final newMissingTokenIDs =
        missingTokenIDs.toSet().difference(tokenIDs).toList();
    final newTokens = this.tokens + tokens;

    return AppFeedData(
      events: events,
      tokens: newTokens,
      next: next,
      missingTokenIDs: newMissingTokenIDs,
    );
  }

  AssetToken? findTokenRelatedTo(FeedEvent event) {
    return tokens.firstWhereOrNull((element) => element.id == event.indexerID);
  }

  Map<AssetToken, List<FeedEvent>> get tokenEventMap {
    final tokenEventMap = <AssetToken, List<FeedEvent>>{};
    for (FeedEvent event in events) {
      final token = findTokenRelatedTo(event);
      if (token == null) continue;

      if (tokenEventMap[token] != null) {
        tokenEventMap[token]!.add(event);
      } else {
        tokenEventMap[token] = [event];
      }
    }
    return tokenEventMap;
  }
}

class FeedServiceImpl extends FeedService {
  static const REFRESH_FOLLOWINGS = 'REFRESH_FOLLOWINGS';
  static const FETCH_FEEDS = 'FETCH_FEEDS';
  static const FETCH_TOKENS_BY_INDEXIDS = 'FETCH_TOKENS_BY_INDEXIDS';
  static const REFRESH_JWT_TOKEN = 'REFRESH_JWT_TOKEN';

  final Map<String, Completer<void>> _refreshFollowingsCompleters = {};
  final Map<String, Completer<AppFeedData>> _fetchFeedsCompleters = {};
  final Map<String, Completer<List<AssetToken>>>
      _fetchTokensByIndexerIDCompleters = {};

  @override
  ValueNotifier<int> unviewedCount = ValueNotifier(0);

  @override
  ValueNotifier<bool> hasFeed =
      ValueNotifier(injector<ConfigurationService>().hasFeed());

  final ConfigurationService _configurationService;

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;
  var _isolateReady = Completer<void>();
  static SendPort? _isolateSendPort;

  Future<void> get isolateReady => _isolateReady.future;

  FeedServiceImpl(this._configurationService);

  Future<void> start() async {
    if (_sendPort != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessageInMain);

    final jwtToken = (await injector<AuthService>().getAuthToken()).jwtToken;
    _isolate = await Isolate.spawn(_isolateEntry, [
      _receivePort!.sendPort,
      jwtToken,
      Environment.feedURL,
      Environment.indexerURL,
      dotenv,
    ]);
  }

  Future startIsolateOrWait() async {
    log.info("[FeedService] startIsolateOrWait");
    if (_sendPort == null) {
      await start();
      await isolateReady;
      //
    } else if (!_isolateReady.isCompleted) {
      await isolateReady;
    }
  }

  @override
  Future refreshFollowings(List<String> artistIds) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer();
    _refreshFollowingsCompleters[uuid] = completer;

    final followings = artistIds;
    followings.removeWhere((element) => element == "");
    followings.remove("0x0000000000000000000000000000000000000000");

    // sendPort
    log.info("[FeedFollowService] start REFRESH_FOLLOWINGS");
    _sendPort!.send([REFRESH_FOLLOWINGS, uuid, followings]);

    return completer.future;
  }

  @override
  Future checkNewFeeds() async {
    log.info("[FeedService] checkNewFeeds");
    final lastTimeOpenFeed = _configurationService.getLastTimeOpenFeed();
    final appFeedData = await fetchFeeds(null);
    final tokenEventMap = appFeedData.tokenEventMap;
    hasFeed.value = tokenEventMap.isNotEmpty;
    _configurationService.setHasFeed(hasFeed.value);
    tokenEventMap.removeWhere((key, value) {
      return (value.firstWhereOrNull((element) =>
              element.timestamp.millisecondsSinceEpoch > lastTimeOpenFeed) ==
          null);
    });
    unviewedCount.value = tokenEventMap.length;
    log.info("[FeedService] ${unviewedCount.value} unread feeds");
  }

  @override
  Future<AppFeedData> fetchFeeds(
    FeedNext? next, {
    List<String> ignoredTokenIds = const [],
  }) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<AppFeedData>();
    _fetchFeedsCompleters[uuid] = completer;

    log.info("[FeedFollowService] start FETCH_FEEDS");
    final isTestnet = Environment.appTestnetConfig;
    _sendPort!.send([
      FETCH_FEEDS,
      uuid,
      isTestnet,
      next?.serial,
      next?.timestamp,
      ignoredTokenIds,
    ]);

    return completer.future;
  }

  @override
  Future<List<AssetToken>> fetchTokensByIndexerID(
      List<String> indexerIDs) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<List<AssetToken>>();
    _fetchTokensByIndexerIDCompleters[uuid] = completer;

    final isTestnet = Environment.appTestnetConfig;
    _sendPort!.send([FETCH_TOKENS_BY_INDEXIDS, uuid, isTestnet, indexerIDs]);

    return completer.future;
  }

  @override
  Future refreshJWTToken(String jwtToken) async {
    if (_sendPort == null) return;
    _sendPort!.send([REFRESH_JWT_TOKEN, jwtToken]);
  }

  static void _isolateEntry(List<dynamic> arguments) async {
    SendPort sendPort = arguments[0];
    dotenv = arguments[4];

    final receivePort = ReceivePort();
    receivePort.listen(_handleMessageInIsolate);

    _setupInjector(
      arguments[1],
      arguments[2],
      arguments[3],
    );
    sendPort.send(receivePort.sendPort);
    _isolateSendPort = sendPort;
  }

  void _handleMessageInMain(dynamic message) async {
    if (message is SendPort) {
      _sendPort = message;
      if (!_isolateReady.isCompleted) {
        _isolateReady.complete();
      }
      return;
    }

    final result = message;
    log.info('[FeedFollowService] $result');
    if (result is RefreshFollowingsSuccess) {
      _refreshFollowingsCompleters[result.uuid]?.complete();
      _refreshFollowingsCompleters.remove(result.uuid);
      //
    } else if (result is RefreshFollowingFailure) {
      Sentry.captureException(result.exception);
      _refreshFollowingsCompleters[result.uuid]
          ?.completeError(result.exception);
      _refreshFollowingsCompleters.remove(result.uuid);
      //
    } else if (result is FetchFeedsSuccess) {
      _fetchFeedsCompleters[result.uuid]?.complete(result.appFeedData);
      _fetchFeedsCompleters.remove(result.uuid);
      //
    } else if (result is FetchFeedsFailure) {
      final exception = result.exception;
      _fetchFeedsCompleters[result.uuid]?.completeError(exception);
      _fetchFeedsCompleters.remove(result.uuid);
      if (exception is DioException && exception.response?.statusCode == 403) {
        _isolateRetryParams = result.fetchParams;
        injector<AuthService>().getAuthToken(forceRefresh: true);
      } else {
        Sentry.captureException(exception);
      }
      //
    } else if (result is FetchTokensByIndexerIDSuccess) {
      _fetchTokensByIndexerIDCompleters[result.uuid]?.complete(result.tokens);
      _fetchTokensByIndexerIDCompleters.remove(result.uuid);
      //
    } else if (result is FetchTokensByIndexerIDFailure) {
      _fetchTokensByIndexerIDCompleters[result.uuid]
          ?.completeError(result.exception);
      _fetchTokensByIndexerIDCompleters.remove(result.uuid);
    }
  }

  // Isolate
  static late QuickAuthInterceptor _quickAuthInterceptor;
  static List<dynamic>? _isolateRetryParams;

  static void _handleMessageInIsolate(dynamic message) {
    if (message is List<dynamic>) {
      switch (message[0]) {
        case REFRESH_FOLLOWINGS:
          _refreshFollowings(message[1], message[2]);
          break;

        case FETCH_FEEDS:
          _fetchFeeds(
              message[1], message[2], message[3], message[4], message[5]);
          break;

        case FETCH_TOKENS_BY_INDEXIDS:
          _fetchTokensByIndexerID(message[1], message[2], message[3]);
          break;

        case REFRESH_JWT_TOKEN:
          _quickAuthInterceptor.jwtToken = message[1];
          if (_isolateRetryParams != null) {
            List<dynamic> params = _isolateRetryParams!;
            _isolateRetryParams = null;
            _handleMessageInIsolate(params);
          }
      }
    }
  }

  static void _setupInjector(
      String jwtToken, String feedURL, String indexerURL) {
    _quickAuthInterceptor = QuickAuthInterceptor(jwtToken);

    final authenticatedDio = Dio(); // Authenticated dio instance for AU servers
    authenticatedDio.interceptors.add(_quickAuthInterceptor);
    authenticatedDio.interceptors.add(LoggingInterceptor());
    authenticatedDio.options = BaseOptions(followRedirects: true);
    injector.registerLazySingleton(
        () => FeedApi(authenticatedDio, baseUrl: feedURL));

    final dio = Dio();
    injector.registerLazySingleton(() => IndexerApi(dio, baseUrl: indexerURL));
    testnetInjector
        .registerLazySingleton(() => IndexerApi(dio, baseUrl: indexerURL));

    final indexerClient = IndexerClient(indexerURL);

    injector.registerLazySingleton<IndexerService>(
        () => IndexerService(indexerClient));
  }

  static void _refreshFollowings(String uuid, List<String> followings) async {
    try {
      // add followings
      if (followings.isNotEmpty) {
        await injector<FeedApi>().postFollows({
          "addresses": followings,
        });
      }

      // remove unfollowings
      List<String> remoteFollowings = [];
      var loop = true;
      FeedNext? next;

      while (loop) {
        final followingData = await injector<FeedApi>()
            .getFollows(100, next?.serial, next?.timestamp);
        remoteFollowings.addAll(followingData.followings.map((e) => e.address));
        loop = followingData.followings.length >= 100;
        next = followingData.next;
      }

      final deletingFollowings =
          remoteFollowings.toSet().difference(followings.toSet()).toList();
      if (deletingFollowings.isNotEmpty) {
        await injector<FeedApi>().deleteFollows({
          "addresses": deletingFollowings,
        });
      }

      // side-effect: request reindex for followings so that user can view their gallery
      for (var following in followings) {
        final blockchain = following.blockchainForAddress;
        if (blockchain == null) continue;
        injector<IndexerApi>()
            .requestIndex({"owner": following, "blockchain": blockchain});
      }

      _isolateSendPort?.send(RefreshFollowingsSuccess(uuid));
    } catch (exception) {
      _isolateSendPort?.send(RefreshFollowingFailure(uuid, exception));
    }
  }

  static void _fetchFeeds(
    String uuid,
    bool isTestnet,
    String? serial,
    String? timestamp,
    List<String> ignoredTokenIds,
  ) async {
    try {
      const count = 50;
      final feedData = await injector<FeedApi>()
          .getFeeds(isTestnet, count, serial, timestamp);

      final next = feedData.events.length < count ? null : feedData.next;

      feedData.events = feedData.events
          .distinctBy(keyOf: (e) => e.uniqueKey)
          .whereNot((e) => ignoredTokenIds.contains(e.indexerID))
          .toList();

      List<String> indexerIDs = [];
      for (var feed in feedData.events) {
        indexerIDs.add(feed.indexerID);
      }

      final indexerService = injector<IndexerService>();

      final List<AssetToken> tokens = indexerIDs.isNotEmpty
          ? (await indexerService
              .getNftTokens(QueryListTokensRequest(ids: indexerIDs)))
          : [];

      // Get missing tokens
      final eventsWithMissingToken = feedData.events.where(
        (event) =>
            tokens.firstWhereOrNull((token) => token.id == event.indexerID) ==
            null,
      );

      final missingTokenIDs =
          eventsWithMissingToken.map((e) => e.indexerID).toList();

      _isolateSendPort?.send(FetchFeedsSuccess(
        uuid,
        AppFeedData(
            events: feedData.events,
            tokens: tokens,
            next: next,
            missingTokenIDs: missingTokenIDs),
      ));
    } catch (exception) {
      _isolateSendPort?.send(FetchFeedsFailure(uuid, exception, [
        FETCH_FEEDS,
        uuid,
        isTestnet,
        serial,
        timestamp,
        ignoredTokenIds,
      ]));
    }
  }

  static void _fetchTokensByIndexerID(
      String uuid, bool isTestnet, List<String> indexerIDs) async {
    try {
      final indexerService = injector<IndexerService>();

      final List<AssetToken> tokens = indexerIDs.isNotEmpty
          ? (await indexerService
              .getNftTokens(QueryListTokensRequest(ids: indexerIDs)))
          : [];
      _isolateSendPort?.send(FetchTokensByIndexerIDSuccess(uuid, tokens));
    } catch (exception) {
      _isolateSendPort?.send(FetchTokensByIndexerIDFailure(uuid, exception));
    }
  }

  void disposeIsolate() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _receivePort?.close();
    _isolateReady = Completer<void>();
  }
}

abstract class FeedServiceResult {}

class RefreshFollowingsSuccess extends FeedServiceResult {
  final String uuid;

  RefreshFollowingsSuccess(
    this.uuid,
  );
}

class RefreshFollowingFailure extends FeedServiceResult {
  final String uuid;
  final Object exception;

  RefreshFollowingFailure(this.uuid, this.exception);
}

class FetchFeedsSuccess extends FeedServiceResult {
  final String uuid;
  final AppFeedData appFeedData;

  FetchFeedsSuccess(this.uuid, this.appFeedData);
}

class FetchFeedsFailure extends FeedServiceResult {
  final String uuid;
  final Object exception;
  final List<dynamic> fetchParams;

  FetchFeedsFailure(this.uuid, this.exception, this.fetchParams);
}

class FetchTokensByIndexerIDSuccess extends FeedServiceResult {
  final String uuid;
  final List<AssetToken> tokens;

  FetchTokensByIndexerIDSuccess(this.uuid, this.tokens);
}

class FetchTokensByIndexerIDFailure extends FeedServiceResult {
  final String uuid;
  final Object exception;

  FetchTokensByIndexerIDFailure(this.uuid, this.exception);
}
