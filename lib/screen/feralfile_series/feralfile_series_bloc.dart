import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class FeralFileSeriesBloc
    extends AuBloc<FeralFileSeriesEvent, FeralFileSeriesState> {
  final FeralFileService _feralFileService;

  FeralFileSeriesBloc(this._feralFileService) : super(FeralFileSeriesState()) {
    on<FeralFileSeriesGetSeriesEvent>((event, emit) async {
      final result = await Future.wait([
        _feralFileService.getSeries(event.seriesId),
        _feralFileService.getSeriesArtworks(event.seriesId),
      ]);
      final series = result[0] as FFSeries;
      final artworks = result[1] as List<Artwork>;
      final exhibitionDetail = series.exhibition == null
          ? null
          : ExhibitionDetail(
              exhibition: series.exhibition!,
              artworks: artworks,
            );
      final tokenIds = exhibitionDetail == null
          ? null
          : artworks
              .map((e) => exhibitionDetail.getArtworkTokenId(e) ?? '')
              .toList();
      emit(state.copyWith(
        exhibitionDetail: exhibitionDetail,
        series: series,
        artworks: artworks,
        tokenIds: tokenIds,
      ));
    });
  }
}
