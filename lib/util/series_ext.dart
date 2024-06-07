import 'package:autonomy_flutter/model/ff_series.dart';

extension FFSeriesExt on FFSeries {
  String get displayTitle {
    final year = mintedAt?.year ?? createdAt?.year;
    return year != null ? '$title ($year)' : title;
  }

  String get galleryURL => (metadata?['galleryURL'] ?? '') as String;

  int? get latestRevealedArtworkIndex =>
      metadata?['latestRevealedArtworkIndex'];
}
