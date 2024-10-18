import 'package:autonomy_flutter/model/explore_statistics_data.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';

class FeralfileHomeBlocState {
  final ExploreStatisticsData? exploreStatisticsData;

  List<Artwork>? featuredArtworks;

  FeralfileHomeBlocState({
    this.exploreStatisticsData,
    this.featuredArtworks,
  });

  FeralfileHomeBlocState copyWith({
    ExploreStatisticsData? exploreStatisticsData,
    List<Artwork>? featuredArtworks,
  }) =>
      FeralfileHomeBlocState(
        exploreStatisticsData:
            exploreStatisticsData ?? this.exploreStatisticsData,
        featuredArtworks: featuredArtworks ?? this.featuredArtworks,
      );
}
