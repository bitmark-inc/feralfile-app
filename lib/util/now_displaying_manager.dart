import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';

class NowDisplayingManager {
  factory NowDisplayingManager() => _instance;

  NowDisplayingManager._internal();

  static final NowDisplayingManager _instance =
      NowDisplayingManager._internal();

  NowDisplayingStatus? nowDisplayingStatus;
  final StreamController<NowDisplayingStatus?> _streamController =
      StreamController.broadcast();

  Stream<NowDisplayingStatus?> get nowDisplayingStream =>
      _streamController.stream;

  void addStatus(NowDisplayingStatus status) {
    _streamController.add(status);
  }

  Future<void> updateDisplayingNow() async {
    try {
      final status = await _getStatus();
      if (status == null) {
        return;
      }
      final nowDisplaying = await getNowDisplayingObject(status);
      if (nowDisplaying == null) {
        return;
      }
      final nowDisplayingStatus = NowDisplayingSuccess(nowDisplaying);
      this.nowDisplayingStatus = nowDisplayingStatus;
      addStatus(nowDisplayingStatus);
    } catch (e) {
      addStatus(NowDisplayingError(e));
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

  Future<CheckDeviceStatusReply?> _getStatus() {
    final device = injector<FFBluetoothService>().castingBluetoothDevice;
    if (device == null) {
      return Future.value();
    }
    final completer = Completer<CheckDeviceStatusReply>();
    injector<CanvasDeviceBloc>().add(
      CanvasDeviceGetStatusEvent(
        device,
        onDoneCallback: (status) {
          completer.complete(status);
        },
      ),
    );
    return completer.future;
  }
}
