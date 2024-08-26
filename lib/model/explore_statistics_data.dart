import 'package:autonomy_flutter/util/feral_file_explore_helper.dart';

class ExploreStatisticsData {
  final int exhibition;
  final int artwork;
  final int artist;
  final int curator;

  ExploreStatisticsData({
    required this.exhibition,
    required this.artwork,
    required this.artist,
    required this.curator,
  });

  factory ExploreStatisticsData.fromJson(Map<String, dynamic> json) =>
      ExploreStatisticsData(
        exhibition: json['exhibition'] as int,
        artwork: json['artwork'] as int,
        artist: json['artist'] as int,
        curator: json['curator'] as int,
      );
}

extension ExploreStatisticsDataExt on ExploreStatisticsData {
  int get totalExhibition => exhibition + 1; // +1 for source exhibition

  int get totalArtwork => artwork;

  int get totalArtist => artist;

  int get totalCurator =>
      curator - FeralFileExploreHelper.ignoreCuratorIds.length;
}
