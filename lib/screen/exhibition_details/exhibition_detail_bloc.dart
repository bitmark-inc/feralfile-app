// create exhibition_detail bloc

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class ExhibitionDetailBloc
    extends AuBloc<ExhibitionDetailEvent, ExhibitionDetailState> {
  final FeralFileService _feralFileService;

  ExhibitionDetailBloc(this._feralFileService)
      : super(ExhibitionDetailState()) {
    on<GetExhibitionDetailEvent>((event, emit) async {
      final exhibition = await _feralFileService
          .getExhibition(event.exhibitionId, includeFirstArtwork: true);
      final listSeries = exhibition.series;

      emit(state.copyWith(exhibition: exhibition.copyWith(series: listSeries)));
    });
  }
}
