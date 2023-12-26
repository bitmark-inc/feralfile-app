import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      final featuredExhibition =
          (await _feralFileService.getAllExhibitions(withArtworks: true)).last;
      emit(state.copyWith(exhibitions: [featuredExhibition]));
    });
  }
}
