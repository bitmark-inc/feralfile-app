import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtworkDetailBloc extends Bloc<ArtworkDetailEvent, ArtworkDetailState> {
  FeralFileService _feralFileService;
  AssetTokenDao _assetTokenDao;
  ProvenanceDao _provenanceDao;

  ArtworkDetailBloc(
      this._feralFileService, this._assetTokenDao, this._provenanceDao)
      : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenById(event.id);
      final provenances =
          await _provenanceDao.findProvenanceByTokenID(event.id);

      emit(ArtworkDetailState(asset: asset, provenances: []));

      List<AssetPrice> assetPrices = [];

      if (event.id.startsWith('bmk--')) {
        assetPrices = await _feralFileService
            .getAssetPrices([event.id.replaceAll("bmk--", "")]);
      }

      emit(ArtworkDetailState(
          asset: asset,
          provenances: provenances,
          assetPrice: assetPrices.isNotEmpty ? assetPrices.first : null));
    });
  }
}
