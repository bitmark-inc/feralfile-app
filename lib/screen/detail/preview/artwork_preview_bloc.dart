import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtworkPreviewBloc
    extends Bloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  AssetTokenDao _assetTokenDao;

  ArtworkPreviewBloc(this._assetTokenDao) : super(ArtworkPreviewState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenById(event.id);
      emit(ArtworkPreviewState(asset: asset));
    });
  }
}
