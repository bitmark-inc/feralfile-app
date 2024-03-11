import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';

extension ExhibitionExt on Exhibition {
  String get coverUrl => '${Environment.feralFileAssetURL}/$coverURI';

  bool get isGroupExhibition => type == 'group';

  //TODO: implement this
  bool get isFreeToStream => true;

  //TODO: implement this
  bool get isOnGoing => true;

  String? get getSeriesArtworkModelText {
    const sep = ', ';
    final specifiedSeriesArtworkModelTitle =
        injector<RemoteConfigService>().getConfig<Map<String, dynamic>>(
      ConfigGroup.exhibition,
      ConfigKey.specifiedSeriesArtworkModelTitle,
      specifiedSeriesTitle,
    );
    final specifiedSeriesIds = specifiedSeriesArtworkModelTitle.keys;
    if (this.series == null) {
      return null;
    }
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
      final modelTitle = value.length == 1 ? model.title : model.pluralTitle;
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
}

extension ListExhibitionDetailExt on List<ExhibitionDetail> {
  List<Exhibition> get exhibitions => map((e) => e.exhibition).toList();
}

extension ExhibitionDetailExt on ExhibitionDetail {
  List<String> get seriesIds =>
      artworks?.map((e) => e.seriesID).toSet().toList() ?? [];

  Artwork? representArtwork(String seriesId) =>
      artworks!.firstWhereOrNull((e) => e.seriesID == seriesId);

  List<Artwork> get representArtworks =>
      seriesIds.map((e) => representArtwork(e)).whereNotNull().toList();

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
  String get thumbnailURL => getFFUrl(thumbnailURI);

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
}

String getFFUrl(String uri) {
  if (uri.startsWith('http')) {
    return uri;
  }
  return '${Environment.feralFileAssetURL}/$uri';
}
