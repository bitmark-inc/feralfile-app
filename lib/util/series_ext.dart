import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';

extension FFSeriesExt on FFSeries {
  String get displayTitle {
    final year = mintedAt?.year ?? createdAt?.year;
    final isJohnGerrardSeries = JohnGerrardHelper.seriesIDs.contains(id);
    return (year != null && !isJohnGerrardSeries) ? '$title ($year)' : title;
  }

  bool get isGenerative => GenerativeMediumTypes.values.contains(medium);

  bool get isMultiUnique => settings?.artworkModel == ArtworkModel.multiUnique;

  bool get shouldFakeArtwork {
    final dontFakeArtworkSeriesIds =
        injector<RemoteConfigService>().getConfig<List<dynamic>>(
      ConfigGroup.exhibition,
      ConfigKey.dontFakeArtworkSeriesIds,
      [],
    );
    return !dontFakeArtworkSeriesIds.contains(id);
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
