import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';

extension FFSeriesExt on FFSeries {
  String get displayTitle {
    final year = mintedAt?.year ?? createdAt?.year;
    final isJohnGerrardSeries = JohnGerrardHelper.seriesIDs.contains(id);
    return (year != null && !isJohnGerrardSeries) ? '$title ($year)' : title;
  }

  String get galleryURL => (metadata?['galleryURL'] ?? '') as String;

  int? get latestRevealedArtworkIndex =>
      metadata?['latestRevealedArtworkIndex'];

  String get displayKey => exhibition?.displayKey ?? exhibitionID;

  String? get mediumDescription =>
      metadata != null && metadata!['mediumDescription'] != null
          ? (metadata!['mediumDescription'] as List<dynamic>).join('\n')
          : null;
}
