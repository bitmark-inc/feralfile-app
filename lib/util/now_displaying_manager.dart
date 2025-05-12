import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';

class NowDisplayingManager {
  factory NowDisplayingManager() => _instance;

  NowDisplayingManager._internal();

  static final NowDisplayingManager _instance =
      NowDisplayingManager._internal();

  Timer? _onDisconnectTimer;

  NowDisplayingStatus? nowDisplayingStatus;
  final StreamController<NowDisplayingStatus?> _streamController =
      StreamController.broadcast();

  Stream<NowDisplayingStatus?> get nowDisplayingStream =>
      _streamController.stream;

  void addStatus(NowDisplayingStatus status) {
    log.info('NowDisplayingManager: $status');
    nowDisplayingStatus = status;
    _streamController.add(status);
    _onDisconnectTimer?.cancel();
    if (status is ConnectFailed) {
      _onDisconnectTimer = Timer(const Duration(seconds: 5), () {
        shouldShowNowDisplayingOnDisconnect.value = false;
      });
    } else if (status is ConnectionLostAndReconnecting) {
      _onDisconnectTimer = Timer(const Duration(seconds: 10), () {
        shouldShowNowDisplayingOnDisconnect.value = false;
        injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent());
      });
    } else if (status is NowDisplayingSuccess || status is ConnectSuccess) {
      shouldShowNowDisplayingOnDisconnect.value = true;
    }
    nowDisplayingVisibility.value = true;
    injector<NavigationService>().hideDeviceSettings();
  }

  Future<void> updateDisplayingNow({bool addStatusOnError = true}) async {
    try {
      log.info('NowDisplayingManager: updateDisplayingNow');
      final device = BluetoothDeviceHelper().castingBluetoothDevice;
      if (device == null) {
        return;
      }

      CheckDeviceStatusReply? status;
      try {
        status = await _getStatus(device);
      } catch (e) {
        log.info(
          'NowDisplayingManager: updateDisplayingNow error: $e, retrying',
        );
      }
      if (status == null) {
        throw Exception('Failed to get Now Displaying');
      }
      final nowDisplaying = await getNowDisplayingObject(status);
      if (nowDisplaying == null) {
        return;
      }
      nowDisplayingStatus = NowDisplayingSuccess(nowDisplaying);
      addStatus(nowDisplayingStatus!);
    } catch (e) {
      log.info('NowDisplayingManager: updateDisplayingNow error: $e');
      if (addStatusOnError) {
        addStatus(NowDisplayingError(e));
      }
    }
  }

  Future<NowDisplayingObject?> getNowDisplayingObject(
    CheckDeviceStatusReply status,
  ) async {
    if (status.exhibitionId != null) {
      final exhibitionId = status.exhibitionId!;
      final exhibition = await injector<FeralFileService>().getExhibition(
        exhibitionId,
      );
      final catalogId = status.catalogId;
      final catalog = catalogId != null ? ExhibitionCatalog.artwork : null;
      Artwork? artwork;
      if (catalog == ExhibitionCatalog.artwork) {
        artwork = await injector<FeralFileService>().getArtwork(
          catalogId!,
        );
      }
      final exhibitionDisplaying = ExhibitionDisplaying(
        exhibition: exhibition,
        catalogId: catalogId,
        catalog: catalog,
        artwork: artwork,
      );
      return NowDisplayingObject(exhibitionDisplaying: exhibitionDisplaying);
    } else if (status.artworks.isNotEmpty) {
      final index = status.currentArtworkIndex;
      if (index == null) {
        return null;
      }
      final tokenId = status.artworks[index].token?.id;
      if (tokenId == null) {
        return null;
      }
      final assetToken = await _fetchAssetToken(tokenId);
      return NowDisplayingObject(assetToken: assetToken);
    } else {
      if (status.displayKey == CastDailyWorkRequest.displayKey) {
        return NowDisplayingObject(
          dailiesWorkState: injector<DailyWorkBloc>().state,
        );
      }
    }
    return null;
  }

  Future<AssetToken?> _fetchAssetToken(String tokenId) async {
    final request = QueryListTokensRequest(ids: [tokenId]);
    final assetToken = await injector<IndexerService>().getNftTokens(request);
    return assetToken.isNotEmpty ? assetToken.first : null;
  }

  Future<CheckDeviceStatusReply?> _getStatus(FFBluetoothDevice device) async {
    final completer = Completer<CheckDeviceStatusReply?>();
    injector<CanvasDeviceBloc>().add(
      CanvasDeviceGetStatusEvent(
        device,
        onDoneCallback: (status) {
          completer.complete(status);
        },
        onErrorCallback: (e) {
          completer.completeError(e);
        },
      ),
    );
    final res = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Timeout getting Now Displaying');
      },
    );
    return res;
  }
}
