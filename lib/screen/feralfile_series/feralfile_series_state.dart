import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';

class FeralFileSeriesEvent {}

class FeralFileSeriesGetSeriesEvent extends FeralFileSeriesEvent {
  final String seriesId;

  FeralFileSeriesGetSeriesEvent(this.seriesId);
}

class FeralFileSeriesState {
  final ExhibitionDetail? exhibitionDetail;
  final FFSeries? series;
  final List<Artwork> artworks;
  final List<String> tokenIds;

  FeralFileSeriesState({
    this.exhibitionDetail,
    this.series,
    this.artworks = const [],
    this.tokenIds = const [],
  });

  FeralFileSeriesState copyWith({
    ExhibitionDetail? exhibitionDetail,
    FFSeries? series,
    List<Artwork>? artworks,
    List<String>? tokenIds,
  }) =>
      FeralFileSeriesState(
        exhibitionDetail: exhibitionDetail ?? this.exhibitionDetail,
        series: series ?? this.series,
        artworks: artworks ?? this.artworks,
        tokenIds: tokenIds ?? this.tokenIds,
      );
}
