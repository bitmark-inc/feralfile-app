// create exhibition_detail bloc

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class ExhibitionDetailBloc
    extends AuBloc<ExhibitionDetailEvent, ExhibitionDetailState> {
  final FeralFileService _feralFileService;

  ExhibitionDetailBloc(this._feralFileService)
      : super(ExhibitionDetailState()) {
    on<SaveExhibitionEvent>((event, emit) {
      emit(state.copyWith(exhibition: event.exhibition));
      add(GetArtworksEvent());
    });

    on<GetArtworksEvent>((event, emit) async {
      final artworks = await _feralFileService.getExhibitionArtworks(
        state.exhibition!.id,
      );
      emit(state.copyWith(artworks: artworks));
    });
  }
}
