import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';
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

  bool get isGenerative =>
      GenerativeMediumTypes.values.any((element) => element.value == medium);

  bool get isMultiUnique => settings?.artworkModel == ArtworkModel.multiUnique;

  bool get isSingle =>
      settings?.artworkModel == ArtworkModel.single ||
      settings?.artworkModel == ArtworkModel.multi;

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
      int.tryParse(metadata?['latestRevealedArtworkIndex']?.toString() ?? '');

  String get displayKey => exhibition?.displayKey ?? exhibitionID;

  String? get mediumDescription =>
      metadata != null && metadata!['mediumDescription'] != null
          ? (metadata!['mediumDescription'] as List<dynamic>).join('\n')
          : null;

  String? get thumbnailUrl {
    final uri = (thumbnailDisplay?.isNotEmpty ?? false)
        ? thumbnailDisplay!
        : thumbnailURI;
    return getFFUrl(uri);
  }

  List<SecondaryMarket> listSecondaryMarkets() {
    final metadata = this.metadata;
    final secondaryMarkets = metadata?['secondaryMarkets'] as List?;
    if (secondaryMarkets == null) {
      return [];
    }
    return secondaryMarkets
        .map((e) => SecondaryMarket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _convertExternalLinkToSlug(List<SecondaryMarket> secondaryMarkets) {
    if (secondaryMarkets.isEmpty) {
      return '';
    }
    for (final secondaryLink in secondaryMarkets) {
      if (secondaryLink.name == 'OpenSea') {
        final collectionSlug = secondaryLink.url.split('collection/').last;
        return collectionSlug.split('?').first;
      }
    }

    return '';
  }

  String externalLinkToSlug() =>
      _convertExternalLinkToSlug(listSecondaryMarkets());

  List<String> listContracts() {
    final exhibition = this.exhibition;
    return exhibition?.contracts?.map((e) => e.address).toList() ?? [];
  }
}

extension FFSeriesListExt on List<FFSeries> {
  List<FFSeries> get displayable => where((e) => e.artwork != null).toList();

  List<FFSeries> get sorted {
    sort((a, b) {
      if (a.displayIndex == b.displayIndex) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        } else {
          return 0;
        }
      }
      return (a.displayIndex ?? 0) - (b.displayIndex ?? 0);
    });
    return this;
  }

  List<ArtistCollection> mergeIndexerCollection(
    List<UserCollection> collections,
  ) =>
      mergeCollectionAndSeries(collections, this);
}

List<ArtistCollection> mergeCollectionAndSeries(
  List<UserCollection> collections,
  List<FFSeries> series,
) {
  final result = <ArtistCollection>[...series];
  for (final collection in collections) {
    final exhibitionContract = <String>[];
    for (final s in series) {
      exhibitionContract.addAll(s.listContracts());
    }
    exhibitionContract.toSet().toList();
    final isDuplicated = series
        .any((s) => s.externalLinkToSlug().contains(collection.externalID));
    if (!isDuplicated) {
      result.add(collection);
    }
  }
  return result;
}
