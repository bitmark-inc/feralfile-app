// create exhibition_detail bloc

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class ExhibitionDetailBloc
    extends AuBloc<ExhibitionDetailEvent, ExhibitionDetailState> {
  final FeralFileService _feralFileService;

  ExhibitionDetailBloc(this._feralFileService)
      : super(ExhibitionDetailState()) {
    on<GetExhibitionDetailEvent>((event, emit) async {
      final result = await Future.wait([
        _feralFileService.getExhibition(event.exhibitionId),
        _feralFileService.getExhibitionArtworks(event.exhibitionId)
      ]);
      final exhibitionDetail = ExhibitionDetail(
          exhibition: result[0] as Exhibition,
          artworks: result[1] as List<Artwork>);
      exhibitionDetail.artworks!.sort((a, b) {
        if (a.index != b.index) {
          return a.index.compareTo(b.index);
        }
        return a.seriesID.compareTo(b.seriesID);
      });
      exhibitionDetail.artworks!.removeWhere(
          (element) => exhibitionDetail.getArtworkTokenId(element) == null);
      emit(state.copyWith(exhibitionDetail: exhibitionDetail));
    });
  }
}
