import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/util/constants.dart';

extension FFSeriesExt on FFSeries {
  String get displayTitle {
    final year = mintedAt?.year ?? createdAt?.year;
    return (year != null && exhibitionID != JOHN_GERRARD_EXHIBITION_ID)
        ? '$title ($year)'
        : title;
  }

  String get galleryURL => (metadata?['galleryURL'] ?? '') as String;

  int? get latestRevealedArtworkIndex =>
      metadata?['latestRevealedArtworkIndex'];
}
