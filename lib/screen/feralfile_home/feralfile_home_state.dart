import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/service/address_service.dart';

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
  }) {
    return FeralfileHomeBlocState(
      exploreStatisticsData:
          exploreStatisticsData ?? this.exploreStatisticsData,
      featuredArtworks: featuredArtworks ?? this.featuredArtworks,
    );
  }
}
