import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      final featuredExhibition =
          (await _feralFileService.getAllExhibitions()).last;
      final artworks =
          await _feralFileService.getExhibitionArtworks(featuredExhibition.id);
      emit(state.copyWith(exhibitions: [
        ExhibitionDetail(exhibition: featuredExhibition, artworks: artworks)
      ]));
    });
  }
}
