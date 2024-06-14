import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/util/john_gerrard_hepler.dart';

extension FFSeriesExt on FFSeries {
  String get displayTitle {
    final year = mintedAt?.year ?? createdAt?.year;
    final isJohnGerrardSeries = JohnGerrardHelper.seriesIDs.contains(id);
    return (year != null && !isJohnGerrardSeries) ? '$title ($year)' : title;
  }

  String get galleryURL => (metadata?['galleryURL'] ?? '') as String;

  int? get latestRevealedArtworkIndex =>
      metadata?['latestRevealedArtworkIndex'];
}
