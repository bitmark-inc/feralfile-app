import 'dart:async';
import 'dart:isolate';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/gateway/feed_api.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class FeedService {
  Future refreshFollowings();
  Future<AppFeedData> fetchFeeds(FeedNext? next);
  Future<List<AssetToken>> fetchTokensByIndexerID(List<String> indexerIDs);
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
}

final testnetInjector = GetIt.asNewInstance();

class FeedServiceImpl extends FeedService {
  NetworkConfigInjector _networkConfigInjector;
  ConfigurationService _configurationService;

  static const REFRESH_FOLLOWINGS = 'REFRESH_FOLLOWINGS';
  static const FETCH_FEEDS = 'FETCH_FEEDS';
  static const FETCH_TOKENS_BY_INDEXIDS = 'FETCH_TOKENS_BY_INDEXIDS';
  Map<String, Completer<void>> _refreshFollowingsCompleters = {};
  Map<String, Completer<AppFeedData>> _fetchFeedsCompleters = {};
  Map<String, Completer<List<AssetToken>>> _fetchTokensByIndexerIDCompleters =
      {};

  FeedServiceImpl(this._networkConfigInjector, this._configurationService);

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;
  var _isolateReady = Completer<void>();
  static SendPort? _isolateSendPort;
  Future<void> get isolateReady => _isolateReady.future;

  AssetTokenDao get _assetDao =>
      _networkConfigInjector.I<AppDatabase>().assetDao;

  Future<void> start() async {
    if (_sendPort != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessageInMain);

    final jwtToken = (await injector<AuthService>().getAuthToken()).jwtToken;
    _isolate = await Isolate.spawn(_isolateEntry, [
      _receivePort!.sendPort,
      jwtToken,
      Environment.feedURL,
      Environment.indexerMainnetURL,
      Environment.indexerTestnetURL,
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

  Future refreshFollowings() async {
    await startIsolateOrWait();

    final uuid = Uuid().v4();
    final completer = Completer();
    _refreshFollowingsCompleters[uuid] = completer;

    final followings = await _assetDao.findAllAssetArtistIDs();
    followings.removeWhere((element) => element == "");

    // sendPort
    log.info("[FeedFollowService] start REFRESH_FOLLOWINGS");
    _sendPort!.send([REFRESH_FOLLOWINGS, uuid, followings]);

    return completer.future;
  }

  Future<AppFeedData> fetchFeeds(FeedNext? next) async {
    await startIsolateOrWait();

    final uuid = Uuid().v4();
    final completer = Completer<AppFeedData>();
    _fetchFeedsCompleters[uuid] = completer;

    log.info("[FeedFollowService] start FETCH_FEEDS");
    final isTestnet = _configurationService.getNetwork() == Network.TESTNET;
    _sendPort!
        .send([FETCH_FEEDS, uuid, isTestnet, next?.serial, next?.timestamp]);

    return completer.future;
  }

  Future<List<AssetToken>> fetchTokensByIndexerID(
      List<String> indexerIDs) async {
    await startIsolateOrWait();

    final uuid = Uuid().v4();
    final completer = Completer<List<AssetToken>>();
    _fetchTokensByIndexerIDCompleters[uuid] = completer;

    final isTestnet = _configurationService.getNetwork() == Network.TESTNET;
    _sendPort!.send([FETCH_TOKENS_BY_INDEXIDS, uuid, isTestnet, indexerIDs]);

    return completer.future;
  }

  static void _isolateEntry(List<dynamic> arguments) async {
    SendPort sendPort = arguments[0];

    final receivePort = ReceivePort();
    receivePort.listen(_handleMessageInIsolate);

    _setupInjector(arguments[1], arguments[2], arguments[3], arguments[4]);
    sendPort.send(receivePort.sendPort);
    _isolateSendPort = sendPort;
  }

  void _handleMessageInMain(dynamic message) async {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();

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
      _fetchFeedsCompleters[result.uuid]?.completeError(result.exception);
      _fetchFeedsCompleters.remove(result.uuid);
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

  static void _handleMessageInIsolate(dynamic message) {
    if (message is List<dynamic>) {
      switch (message[0]) {
        case REFRESH_FOLLOWINGS:
          _refreshFollowings(message[1], message[2]);
          break;

        case FETCH_FEEDS:
          _fetchFeeds(message[1], message[2], message[3], message[4]);
          break;

        case FETCH_TOKENS_BY_INDEXIDS:
          _fetchTokensByIndexerID(message[1], message[2], message[3]);
          break;
      }
    }
  }

  static void _setupInjector(String jwtToken, String feedURL,
      String indexerMainnetURL, String indexerTestnetURL) {
    final authenticatedDio = Dio(); // Authenticated dio instance for AU servers
    authenticatedDio.interceptors.add(QuickAuthInterceptor(jwtToken));
    authenticatedDio.interceptors.add(LoggingInterceptor());
    (authenticatedDio.transformer as DefaultTransformer).jsonDecodeCallback =
        parseJson;
    authenticatedDio.options = BaseOptions(followRedirects: true);
    injector.registerLazySingleton(
        () => FeedApi(authenticatedDio, baseUrl: feedURL));

    final dio = Dio();
    injector.registerLazySingleton(
        () => IndexerApi(dio, baseUrl: indexerMainnetURL));
    testnetInjector.registerLazySingleton(
        () => IndexerApi(dio, baseUrl: indexerTestnetURL));
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
      String uuid, bool isTestnet, String? serial, String? timestamp) async {
    try {
      final count = 50;
      final feedData = await injector<FeedApi>()
          .getFeeds(isTestnet, count, serial, timestamp);

      List<String> indexerIDs = [];
      for (var feed in feedData.events) {
        indexerIDs.add(feed.indexerID);
      }

      final indexerAPI =
          isTestnet ? testnetInjector<IndexerApi>() : injector<IndexerApi>();
      final tokens = (await indexerAPI.getNftTokens({"ids": indexerIDs}))
          .map((e) => AssetToken.fromAsset(e))
          .toList();

      final next = feedData.events.length < 50 ? null : feedData.next;

      // Get missing tokens
      final eventsWithMissingToken = feedData.events.where(
        (event) =>
            tokens.firstWhereOrNull((token) => token.id == event.indexerID) ==
            null,
      );

      // RequestIndex for missing tokens
      for (final event in eventsWithMissingToken.slices(5).first) {
        log.info(
            "RequestIndexOne ${event.recipient} - ${event.contract} - ${event.tokenID}");
        indexerAPI.requestIndexOne({
          "owner": event.recipient,
          "contract": event.contract,
          "tokenID": event.tokenID,
          "dryrun": false,
        });
      }

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
      _isolateSendPort?.send(FetchFeedsFailure(uuid, exception));
    }
  }

  static void _fetchTokensByIndexerID(
      String uuid, bool isTestnet, List<String> indexerIDs) async {
    try {
      final indexerAPI =
          isTestnet ? testnetInjector<IndexerApi>() : injector<IndexerApi>();
      final tokens = (await indexerAPI.getNftTokens({"ids": indexerIDs}))
          .map((e) => AssetToken.fromAsset(e))
          .toList();
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

abstract class FeedFollowServiceResult {}

class RefreshFollowingsSuccess extends FeedFollowServiceResult {
  final String uuid;

  RefreshFollowingsSuccess(
    this.uuid,
  );
}

class RefreshFollowingFailure extends FeedFollowServiceResult {
  final String uuid;
  final Object exception;

  RefreshFollowingFailure(this.uuid, this.exception);
}

class FetchFeedsSuccess extends FeedFollowServiceResult {
  final String uuid;
  final AppFeedData appFeedData;

  FetchFeedsSuccess(this.uuid, this.appFeedData);
}

class FetchFeedsFailure extends FeedFollowServiceResult {
  final String uuid;
  final Object exception;

  FetchFeedsFailure(this.uuid, this.exception);
}

class FetchTokensByIndexerIDSuccess extends FeedFollowServiceResult {
  final String uuid;
  final List<AssetToken> tokens;

  FetchTokensByIndexerIDSuccess(this.uuid, this.tokens);
}

class FetchTokensByIndexerIDFailure extends FeedFollowServiceResult {
  final String uuid;
  final Object exception;

  FetchTokensByIndexerIDFailure(this.uuid, this.exception);
}
