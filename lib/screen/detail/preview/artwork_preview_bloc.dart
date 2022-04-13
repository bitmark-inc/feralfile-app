import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtworkPreviewBloc
    extends Bloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  AssetTokenDao _assetTokenDao;

  ArtworkPreviewBloc(this._assetTokenDao) : super(ArtworkPreviewState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenById(event.id);
      emit(ArtworkPreviewState(asset: asset));

      // change ipfs if the CLOUDFLARE_IPFS_PREFIX has not worked
      try {
        if (asset?.previewURL != null) {
          final response = await callRequest(Uri.parse(asset!.previewURL!));
          print(response.statusCode);
          if (response.statusCode == 520) {
            asset.previewURL = asset.previewURL!.replaceRange(
                0, CLOUDFLARE_IPFS_PREFIX.length, DEFAULT_IPFS_PREFIX);
            _assetTokenDao.insertAsset(asset);
            emit(ArtworkPreviewState(asset: asset));
          }
        }
      } catch (_) {
        // ignore this error
      }
    });
  }
}
