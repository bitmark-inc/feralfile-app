import 'dart:async';
import 'dart:isolate';

import 'package:dio/dio.dart';
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

abstract class FeedFollowService {
  Future refreshFollowings();
}

class FeedFollowServiceImpl extends FeedFollowService {
  NetworkConfigInjector _networkConfigInjector;

  static const REFRESH_FOLLOWINGS = 'REFRESH_FOLLOWINGS';
  Map<String, Completer<void>> _refreshFollowingsCompleters = {};

  FeedFollowServiceImpl(this._networkConfigInjector);

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

    _isolate = await Isolate.spawn(_isolateEntry, [
      _receivePort!.sendPort,
      (await injector<AuthService>().getAuthToken()).jwtToken,
      Environment.feedURL,
    ]);
  }

  Future refreshFollowings() async {
    if (_sendPort == null) {
      log.info("[refreshTokensInIsolate] start isolate");
      await start();
      await isolateReady;
    }

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

  static void _isolateEntry(List<dynamic> arguments) async {
    SendPort sendPort = arguments[0];

    final receivePort = ReceivePort();
    receivePort.listen(_handleMessageInIsolate);

    _setupInjector(arguments[1], arguments[2]);
    sendPort.send(receivePort.sendPort);
    _isolateSendPort = sendPort;
  }

  void _handleMessageInMain(dynamic message) async {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();

      return;
    }

    if (message is List) {
      final result = message[0];
      log.info('[FeedFollowService] $result');
      if (result is RefreshFollowingsSuccess) {
        _refreshFollowingsCompleters[result.uuid]?.complete();
        _refreshFollowingsCompleters.remove(result.uuid);
        // do nothing
      } else if (result is RefreshFollowingFailure) {
        Sentry.captureException(result.exception);
        _refreshFollowingsCompleters[result.uuid]
            ?.completeError(result.exception);
        _refreshFollowingsCompleters.remove(result.uuid);
      }
    }
  }

  static void _handleMessageInIsolate(dynamic message) {
    if (message is List<dynamic>) {
      switch (message[0]) {
        case REFRESH_FOLLOWINGS:
          _refreshFollowings(message[1], message[2]);
          break;
      }
    }
  }

  static void _setupInjector(String jwtToken, String feedURL) {
    final authenticatedDio = Dio(); // Authenticated dio instance for AU servers
    authenticatedDio.interceptors.add(QuickAuthInterceptor(jwtToken));
    authenticatedDio.interceptors.add(LoggingInterceptor());
    (authenticatedDio.transformer as DefaultTransformer).jsonDecodeCallback =
        parseJson;
    authenticatedDio.options = BaseOptions(followRedirects: true);

    injector.registerLazySingleton(
        () => FeedApi(authenticatedDio, baseUrl: feedURL));
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
            .getFollows(null, next?.serial, next?.timestamp);
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

      _isolateSendPort?.send([RefreshFollowingsSuccess(uuid)]);
    } catch (exception) {
      _isolateSendPort?.send([RefreshFollowingFailure(uuid, exception)]);
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
