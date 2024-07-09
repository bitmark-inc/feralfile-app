import 'package:autonomy_flutter/model/ff_series.dart';

class FeralFileSeriesEvent {}

class FeralFileSeriesGetSeriesEvent extends FeralFileSeriesEvent {
  final String seriesId;
  final String exhibitionId;

  FeralFileSeriesGetSeriesEvent(this.seriesId, this.exhibitionId);
}

class FeralFileSeriesState {
  final FFSeries? series;
  final double thumbnailRatio;

  FeralFileSeriesState({
    this.series,
    this.thumbnailRatio = 1.0,
  });

  FeralFileSeriesState copyWith({
    FFSeries? series,
    double? thumbnailRatio,
  }) =>
      FeralFileSeriesState(
        series: series ?? this.series,
        thumbnailRatio: thumbnailRatio ?? this.thumbnailRatio,
      );
}
