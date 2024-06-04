import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';

class FeralFileSeriesEvent {}

class FeralFileSeriesGetSeriesEvent extends FeralFileSeriesEvent {
  final String seriesId;
  final String exhibitionId;

  FeralFileSeriesGetSeriesEvent(this.seriesId, this.exhibitionId);
}

class FeralFileSeriesState {
  final Exhibition? exhibition;
  final FFSeries? series;

  FeralFileSeriesState({
    this.exhibition,
    this.series,
  });

  FeralFileSeriesState copyWith({
    Exhibition? exhibition,
    FFSeries? series,
  }) =>
      FeralFileSeriesState(
        exhibition: exhibition ?? this.exhibition,
        series: series ?? this.series,
      );
}
