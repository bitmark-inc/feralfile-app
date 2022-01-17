import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtworkDetailBloc extends Bloc<ArtworkDetailEvent, ArtworkDetailState> {
  FeralFileService _feralFileService;

  ArtworkDetailBloc(this._feralFileService) : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      state.provenances = await _feralFileService.getAssetProvenance(event.id);
      final assetPrices = await _feralFileService.getAssetPrices([event.id]);
      state.assetPrice = assetPrices.first;

      emit(state);
    });
  }
}
