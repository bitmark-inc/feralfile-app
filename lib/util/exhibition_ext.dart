import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/common.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/crawl_helper.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/http_helper.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:sentry/sentry.dart';

extension ExhibitionExt on Exhibition {
  String get coverUrl {
    if (coverDisplay?.isNotEmpty == true) {
      return getFFUrl(coverDisplay!);
    }
    return '${Environment.feralFileAssetURL}/$coverURI';
  }

  bool get isGroupExhibition => type == 'group';

  bool get isSoloExhibition => type == 'solo';

  bool get isJohnGerrardShow => id == JohnGerrardHelper.exhibitionID;

  bool get isCrawlShow => id == CrawlHelper.exhibitionID;

  DateTime get exhibitionViewAt =>
      exhibitionStartAt.subtract(Duration(seconds: previewDuration ?? 0));

  String get displayKey => id;

  //TODO: implement this
  bool get isOnGoing => true;

  bool get isMinted => status == ExhibitionStatus.issued.index;

  List<FFSeries> get displayableSeries => series?.displayable ?? [];

  List<String> get disableKeys {
    if (isJohnGerrardShow) {
      JohnGerrardHelper.disableKeys;
    }
    return [];
  }

  String? get getSeriesArtworkModelText {
    if (this.series == null || id == SOURCE_EXHIBITION_ID) {
      return null;
    }
    const sep = ', ';
    final specifiedSeriesArtworkModelTitle =
        injector<RemoteConfigService>().getConfig<Map<String, dynamic>>(
      ConfigGroup.exhibition,
      ConfigKey.specifiedSeriesArtworkModelTitle,
      specifiedSeriesTitle,
    );
    final specifiedSeriesIds = specifiedSeriesArtworkModelTitle.keys;
    final currentSpecifiedSeries = this
        .series!
        .where((element) => specifiedSeriesIds.contains(element.id))
        .toList();
    final series = this
        .series!
        .where((element) => !currentSpecifiedSeries.contains(element))
        .toList();

    Map<String, List<FFSeries>> map = {};
    for (var s in series) {
      final saleModel = s.settings?.artworkModel?.value;
      if (map.containsKey(saleModel)) {
        map[saleModel]!.add(s);
      } else {
        map[saleModel ?? ''] = [s];
      }
    }
    final keys = map.keys.toList().sorted((a, b) =>
        (ArtworkModel.fromString(b)?.index ?? 0) -
        (ArtworkModel.fromString(a)?.index ?? 0));
    String text = '';
    for (var key in keys) {
      final length = map[key]!.length;
      final model = ArtworkModel.fromString(key);
      final modelTitle = length == 1 ? model?.title : model?.pluralTitle;
      text += '$length $modelTitle$sep';
    }

    final Map<String, List<String>> currentSpecifiedSeriesArtworkModelTitleMap =
        {};
    for (var s in currentSpecifiedSeries) {
      final saleModel = specifiedSeriesArtworkModelTitle[s.id] ?? '';
      if (currentSpecifiedSeriesArtworkModelTitleMap.containsKey(saleModel)) {
        currentSpecifiedSeriesArtworkModelTitleMap[saleModel]!.add(s.title);
      } else {
        currentSpecifiedSeriesArtworkModelTitleMap[saleModel] = [s.title];
      }
    }

    currentSpecifiedSeriesArtworkModelTitleMap.forEach((key, value) {
      final model = ExtendedArtworkModel.fromTitle(key);
      final modelTitle =
          (value.length == 1 ? model?.title : model?.pluralTitle) ?? key;
      text += '${value.length} $modelTitle$sep';
    });
    final res = text.substring(0, text.length - 2);
    final index = text.substring(0, text.length - 2).lastIndexOf(sep);
    const lastSep = ' and ';
    return index == -1
        ? res
        : res.replaceRange(
            index,
            index + sep.length,
            lastSep,
          );
  }

  List<CustomExhibitionNote> get customExhibitionNote {
    final customNote = <CustomExhibitionNote>[];
    if (isJohnGerrardShow) {
      customNote.addAll(JohnGerrardHelper.customNote);
    }
    return customNote;
  }

  // get all resource, include posts and custom notes
  List<Resource> get allResources {
    final resources = <Resource>[...customExhibitionNote];
    if (posts != null) {
      resources.addAll(posts!);
    }
    return resources;
  }
}

extension ListExhibitionDetailExt on List<ExhibitionDetail> {
  List<Exhibition> get exhibitions => map((e) => e.exhibition).toList();
}

extension ExhibitionDetailExt on ExhibitionDetail {
  String? getArtworkTokenId(Artwork artwork) {
    if (artwork.swap != null) {
      if (artwork.swap!.token == null) {
        return null;
      }
      final chain = artwork.swap!.blockchainType == 'ethereum' ? 'eth' : 'tez';
      final contract = artwork.swap!.contractAddress;
      final id = chain == 'eth'
          ? artwork.swap!.token!.hexToDecimal
          : artwork.swap!.token;
      return '$chain-$contract-$id';
    } else {
      final chain = exhibition.mintBlockchain == 'ethereum' ? 'eth' : 'tez';
      final contract = exhibition.contracts?.firstWhereOrNull(
          (e) => e.blockchainType == exhibition.mintBlockchain);
      final contractAddress = contract?.address;
      if (contractAddress == null) {
        return null;
      }
      final id = artwork.id;
      return '$chain-$contractAddress-$id';
    }
  }
}

// Artwork Ext
extension ArtworkExt on Artwork {
  String get thumbnailURL {
    final uri = (thumbnailDisplay?.isNotEmpty == true)
        ? thumbnailDisplay!
        : thumbnailURI;
    return getFFUrl(uri, variant: CloudFlareVariant.l.value);
  }

  String get previewURL => getFFUrl(previewURI);

  bool get isScrollablePreviewURL {
    final remoteConfigService = injector<RemoteConfigService>();
    final scrollablePreviewURL = remoteConfigService.getConfig<List<String>?>(
      ConfigGroup.feralfileArtworkAction,
      ConfigKey.scrollablePreviewUrl,
      [],
    );
    return scrollablePreviewURL?.contains(previewURL) ?? true;
  }

  String get metricTokenId => '${seriesID}_$id';

  Future<String> renderingType() async {
    final medium = series?.medium ?? 'unknown';
    final mediumType = FeralfileMediumTypes.fromString(medium);
    if (mediumType == FeralfileMediumTypes.image) {
      final contentType = await HttpHelper.contentType(previewURL);
      return contentType;
    } else {
      return mediumType.toRenderingType;
    }
  }

  String? get attributesString {
    if (artworkAttributes == null) {
      return null;
    }

    return artworkAttributes!
        .map((e) => '${e.traitType}: ${e.value}')
        .join('. ');
  }

  FFContract? getContract(Exhibition? exhibition) {
    if (swap != null) {
      if (swap!.token == null) {
        return null;
      }

      return FFContract(
        swap!.contractName,
        swap!.blockchainType,
        swap!.contractAddress,
      );
    }

    return exhibition?.contracts?.firstWhereOrNull(
      (e) => e.blockchainType == exhibition.mintBlockchain,
    );
  }

  String? get indexerTokenId {
    var chain = series!.exhibition!.mintBlockchain.toLowerCase();
    // normal case: tezos or ethereum chain
    if (['tezos', 'ethereum'].contains(chain)) {
      final contract = series!.exhibition!.contracts!.firstWhereOrNull(
        (e) => e.blockchainType == chain,
      );
      if (contract == null) {
        unawaited(Sentry.captureMessage(
          'ArtworkExt: get indexerTokenId failed,'
          ' contract is null for chain: $chain, artworkID: $id',
        ));
        return null;
      }
      final chainPrefix = chain == 'tezos' ? 'tez' : 'eth';
      final contractAddress = contract.address;
      return '$chainPrefix-$contractAddress-$id';
    } else
    // special case: bitmark chain
    if (chain == 'bitmark') {
      // if artwork was burned, get indexerTokenId from swap
      if (swap != null) {
        return swap!.indexerId;
      } else {
        // if artwork was not burned, it's bitmark token
        const chanPrefix = 'bmk';
        final contract = series!.exhibition!.contracts!.firstWhereOrNull(
          (e) => e.blockchainType == chain,
        );
        final contractAddress = contract?.address ?? '';
        return '$chanPrefix-$contractAddress-$id';
      }
    } else {
      unawaited(Sentry.captureMessage(
        'ArtworkExt: get indexerTokenId failed, '
        'unknown chain: $chain, artworkID: $id',
      ));
    }
    return null;
  }
}

String getFFUrl(String uri, {String? variant}) {
  // case 1: cloudflare
  if (uri.startsWith(cloudFlarePrefix)) {
    final imageVariant = getVariantFromCloudFlareImageUrl(uri);
    if (imageVariant != null) {
      return uri;
    }

    return '$uri/${variant ?? CloudFlareVariant.l.value}';
  }

  // case 2 => full cdn
  if (uri.startsWith('http')) {
    return uri;
  }

  //case 3 => cdn
  return '${Environment.feralFileAssetURL}/$uri';
}

extension FFContractExt on FFContract {
  String? getBlockchainUrl() {
    final network = Environment.appTestnetConfig ? 'TESTNET' : 'MAINNET';
    switch ('${network}_$blockchainType') {
      case 'MAINNET_ethereum':
        return 'https://etherscan.io/address/$address';

      case 'TESTNET_ethereum':
        return 'https://goerli.etherscan.io/address/$address';

      case 'MAINNET_tezos':
      case 'TESTNET_tezos':
        return 'https://tzkt.io/$address';
    }
    return null;
  }
}

extension ArtworkSwapxt on ArtworkSwap {
  String get indexerId {
    final chain = blockchainType == 'ethereum' ? 'eth' : 'tez';
    // we should use token instead of artworkID.
    // the artworkId is the id of burned artwork.
    return '$chain-$contractAddress-$token';
  }
}

enum ExhibitionStatus {
  created,
  editorReview,
  operatorReview,
  issuing,
  issued,
}
