import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class FeralFileSeriesBloc
    extends AuBloc<FeralFileSeriesEvent, FeralFileSeriesState> {
  final FeralFileService _feralFileService;

  FeralFileSeriesBloc(this._feralFileService) : super(FeralFileSeriesState()) {
    on<FeralFileSeriesGetSeriesEvent>((event, emit) async {
      final result = await Future.wait([
        _feralFileService.getExhibition(event.exhibitionId),
        _feralFileService.getSeries(event.seriesId,
            exhibitionID: event.exhibitionId),
      ]);
      final exhibition = result[0] as Exhibition;
      final series = result[1] as FFSeries;
      emit(state.copyWith(
        exhibition: exhibition,
        series: series,
      ));
    });
  }
}
