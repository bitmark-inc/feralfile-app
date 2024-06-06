import 'package:autonomy_flutter/model/ff_series.dart';

class FeralFileSeriesEvent {}

class FeralFileSeriesGetSeriesEvent extends FeralFileSeriesEvent {
  final String seriesId;
  final String exhibitionId;

  FeralFileSeriesGetSeriesEvent(this.seriesId, this.exhibitionId);
}

class FeralFileSeriesState {
  final FFSeries? series;

  FeralFileSeriesState({
    this.series,
  });

  FeralFileSeriesState copyWith({
    FFSeries? series,
  }) =>
      FeralFileSeriesState(
        series: series ?? this.series,
      );
}
