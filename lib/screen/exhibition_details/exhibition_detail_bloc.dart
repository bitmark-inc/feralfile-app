// create exhibition_detail bloc

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/log.dart';

class ExhibitionDetailBloc
    extends AuBloc<ExhibitionDetailEvent, ExhibitionDetailState> {
  final FeralFileService _feralFileService;

  static const int _limit = 300;

  ExhibitionDetailBloc(this._feralFileService)
      : super(ExhibitionDetailState()) {
    on<GetExhibitionDetailEvent>((event, emit) async {
      final result = await Future.wait([
        _feralFileService.getExhibition(event.exhibitionId),
        _feralFileService.getExhibitionArtworks(event.exhibitionId,
            withSeries: true)
      ]);
      final exhibition = result[0] as Exhibition;
      final artworks = result[1] as FeralFileListResponse<Artwork>;
      final exhibitionDetail =
          ExhibitionDetail(exhibition: exhibition, artworks: artworks.result);
      emit(state.copyWith(exhibitionDetail: exhibitionDetail));

      if (artworks.paging.shouldLoadMore) {
        //add(LoadMoreArtworkEvent(artworks.paging.limit, _limit));
      }
    });

    on<LoadMoreArtworkEvent>((event, emit) async {
      log.info(
          'LoadMoreArtworkEvent: offset=${event.offset}, limit=${event.limit}');
      final result = await _feralFileService.getExhibitionArtworks(
          state.exhibitionDetail!.exhibition.id,
          withSeries: true,
          offset: event.offset,
          limit: event.limit);
      final exhibitionDetail = state.exhibitionDetail!.copyWith(
        artworks: state.exhibitionDetail!.artworks! + result.result,
      );
      emit(state.copyWith(exhibitionDetail: exhibitionDetail));

      if (result.paging.shouldLoadMore) {
        add(LoadMoreArtworkEvent(event.offset + event.limit, event.limit));
      }
    });
  }
}
