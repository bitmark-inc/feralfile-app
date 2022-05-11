import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class TokensService {
  Future fetchTokensForAddresses(List<String> addresses);
  Future<Stream<int>> refreshTokensInIsolate(List<String> addresses);
  Future insertAssetsWithProvenance(List<Asset> assets);
  Future<List<Asset>> fetchLatestAssets(List<String> addresses, int size);
  void disposeIsolate();
  Future purgeCachedGallery();
}

class TokensServiceImpl extends TokensService {
  NetworkConfigInjector _networkConfigInjector;
  ConfigurationService _configurationService;

  static const REFRESH_ALL_TOKENS = '_refreshAllTokens';
  static const FETCH_TOKENS = '_fetchTokens';

  TokensServiceImpl(this._networkConfigInjector, this._configurationService);

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;
  var _isolateReady = Completer<void>();
  StreamController<int>? _refreshAllTokensWorker;
  List<String>? _currentAddresses;
  Map<String, Completer<void>> _fetchTokensCompleters = {};
  Future<void> get isolateReady => _isolateReady.future;

  AssetTokenDao get _assetDao =>
      _networkConfigInjector.I<AppDatabase>().assetDao;

  Future<void> start() async {
    if (_sendPort != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessageInMain);

    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);
  }

  void disposeIsolate() {
    log.info("[TokensService][disposeIsolate] Start");
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _receivePort?.close();
    _currentAddresses = null;
    _isolateReady = Completer<void>();
    _fetchTokensCompleters = {};
    log.info("[TokensService][disposeIsolate] Done");
  }

  Future purgeCachedGallery() async {
    disposeIsolate();
    final hiddenAssets = await _assetDao.findAllHiddenAssets();
    final hiddenIds = hiddenAssets.map((e) => e.id).toList();

    _configurationService.updateTempStorageHiddenTokenIDs(hiddenIds, true);
    _configurationService.setLatestRefreshTokens(null);
    await _assetDao.removeAll();
  }

  Future<Stream<int>> refreshTokensInIsolate(List<String> addresses) async {
    if (_currentAddresses != null) {
      if (_currentAddresses?.join(",") == addresses.join(",")) {
        log.info("[refreshTokensInIsolate] skip because worker is running");
        return _refreshAllTokensWorker!.stream;
      } else {
        log.info("[refreshTokensInIsolate] kill the obsolete worker");
        disposeIsolate();
      }
    }

    if (_sendPort == null) {
      log.info("[refreshTokensInIsolate] start isolate");
      await start();
      await isolateReady;
    }

    final tokenIDs = await getTokenIDs(addresses);
    await _networkConfigInjector
        .I<AppDatabase>()
        .assetDao
        .deleteAssetsNotIn(tokenIDs);

    final dbTokenIDs = (await _assetDao.findAllAssetTokenIDs()).toSet();

    _refreshAllTokensWorker = StreamController<int>();
    _currentAddresses = addresses;

    _sendPort?.send([
      REFRESH_ALL_TOKENS,
      addresses,
      _indexerURL,
      tokenIDs.toSet().difference(dbTokenIDs),
      _configurationService.getLatestRefreshTokens(),
    ]);
    log.info("[REFRESH_ALL_TOKENS][start]");

    return _refreshAllTokensWorker!.stream;
  }

  String get _indexerURL =>
      _configurationService.getNetwork() == Network.MAINNET
          ? Environment.indexerMainnetURL
          : Environment.indexerTestnetURL;

  Future<List<Asset>> fetchLatestAssets(
      List<String> addresses, int size) async {
    var owners = addresses.join(',');
    return await _networkConfigInjector
        .I<IndexerApi>()
        .getNftTokensByOwner(owners, 0, size);
  }

  Future insertAssetsWithProvenance(List<Asset> assets) async {
    List<AssetToken> tokens = [];
    List<Provenance> provenance = [];

    final dbHiddenAssets = await _assetDao.findAllHiddenAssets();
    final dbHiddenIds = dbHiddenAssets.map((e) => e.id).toList();

    final hiddenAsseIDs =
        _configurationService.getTempStorageHiddenTokenIDs() + dbHiddenIds;

    for (var asset in assets) {
      var token = AssetToken.fromAsset(asset);
      if (hiddenAsseIDs.contains(token.id)) {
        token.hidden = 1;
      }
      tokens.add(token);
      provenance.addAll(asset.provenance);
    }

    await _assetDao.insertAssets(tokens);

    await _networkConfigInjector
        .I<AppDatabase>()
        .provenanceDao
        .insertProvenance(provenance);
  }

  Future<List<String>> getTokenIDs(List<String> addresses) async {
    return _networkConfigInjector
        .I<IndexerApi>()
        .getNftIDsByOwner(addresses.join(","));
  }

  Future fetchTokensForAddresses(List<String> addresses) async {
    if (_sendPort == null) {
      log.info("[refreshTokensInIsolate] start isolate");
      await start();
      await isolateReady;
    }

    final uuid = Uuid().v4();
    final completer = Completer();
    _fetchTokensCompleters[uuid] = completer;

    _sendPort!.send([FETCH_TOKENS, addresses, _indexerURL, uuid]);
    log.info("[FETCH_TOKENS][start] $addresses");
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    receivePort.listen(_handleMessageInIsolate);

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
      final result = message[2];

      switch (message[0]) {
        case REFRESH_ALL_TOKENS:
          if (result is FetchTokensSuccess) {
            await insertAssetsWithProvenance(result.assets);
            log.info(
                "[REFRESH_ALL_TOKENS] receive ${result.assets.length} tokens");

            if (!result.done) {
              _refreshAllTokensWorker?.sink.add(1);
            } else {
              _configurationService.setLatestRefreshTokens(DateTime.now());
              _refreshAllTokensWorker?.close();
              disposeIsolate();
              _configurationService.removeTempStorageHiddenTokenIDs();
              log.info("[REFRESH_ALL_TOKENS][end]");
            }
          } else if (result is FetchTokenFailure) {
            Sentry.captureException(result.exception);
            disposeIsolate();
            log.info("[REFRESH_ALL_TOKENS] end in error ${result.exception}");
          }
          break;

        case FETCH_TOKENS:
          final uuid = message[1];

          if (result is FetchTokensSuccess) {
            insertAssetsWithProvenance(result.assets);
            log.info("[FETCH_TOKENS] receive ${result.assets.length} tokens");
          } else if (result is FetchTokensDone) {
            _fetchTokensCompleters[uuid]?.complete();
            _fetchTokensCompleters.remove(uuid);
            log.info("[FETCH_TOKENS][end]");
          } else if (result is FetchTokenFailure) {
            Sentry.captureException(result.exception);
            disposeIsolate();
            log.info("[FETCH_TOKENS] end in error ${result.exception}");
          }

          break;
        default:
          break;
      }
    }
  }

  static SendPort? _isolateSendPort;

  static void _handleMessageInIsolate(dynamic message) {
    if (message is List<dynamic>) {
      switch (message[0]) {
        case REFRESH_ALL_TOKENS:
          _refreshAllTokens(message[1], message[2], message[3], message[4],
              REFRESH_ALL_TOKENS, '');
          break;

        case FETCH_TOKENS:
          _refreshAllTokens(
              message[1], message[2], {}, null, FETCH_TOKENS, message[3]);
          break;
        default:
          break;
      }
    }
  }

  static void _refreshAllTokens(
      List<String> addresses,
      String indexerApiUrl,
      Set<String> expectedNewTokenIDs,
      DateTime? latestRefreshToken,
      String key,
      String keyUUID) async {
    try {
      final owners = addresses.join(",");

      final _isolateIndexerAPI = IndexerApi(Dio(), baseUrl: indexerApiUrl);

      var offset = 0;
      Set<String> tokenIDs = {};

      while (true) {
        final assets = await _isolateIndexerAPI.getNftTokensByOwner(
            owners, offset, INDEXER_TOKENS_MAXIMUM);
        tokenIDs.addAll(assets.map((e) => e.id));

        if (assets.length < INDEXER_TOKENS_MAXIMUM) {
          _isolateSendPort
              ?.send([key, keyUUID, FetchTokensSuccess(assets, true)]);
          break;
        }

        if (latestRefreshToken != null) {
          expectedNewTokenIDs.difference(tokenIDs);
          if (assets.last.lastActivityTime.compareTo(latestRefreshToken) < 0 &&
              expectedNewTokenIDs.isEmpty) {
            _isolateSendPort
                ?.send([key, keyUUID, FetchTokensSuccess(assets, true)]);
            break;
          }
        }

        _isolateSendPort
            ?.send([key, keyUUID, FetchTokensSuccess(assets, false)]);
        offset += INDEXER_TOKENS_MAXIMUM;
      }
    } catch (exception) {
      _isolateSendPort?.send([key, keyUUID, FetchTokenFailure(exception)]);
    }
  }
}

abstract class TokensServiceResult {}

class FetchTokensSuccess extends TokensServiceResult {
  final List<Asset> assets;
  bool done;

  FetchTokensSuccess(this.assets, this.done);
}

class FetchTokenFailure extends TokensServiceResult {
  final Object exception;

  FetchTokenFailure(this.exception);
}

class FetchTokensDone extends TokensServiceResult {}
