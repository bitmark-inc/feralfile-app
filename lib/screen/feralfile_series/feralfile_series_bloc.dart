import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class FeralFileSeriesBloc
    extends AuBloc<FeralFileSeriesEvent, FeralFileSeriesState> {
  final FeralFileService _feralFileService;

  FeralFileSeriesBloc(this._feralFileService) : super(FeralFileSeriesState()) {
    on<FeralFileSeriesGetSeriesEvent>((event, emit) async {
      final series = await _feralFileService.getSeries(event.seriesId,
          exhibitionID: event.exhibitionId);
      emit(state.copyWith(
        series: series,
      ));
    });
  }
}
