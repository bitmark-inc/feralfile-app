import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';

extension ExhibitionExt on Exhibition {
  String get coverUrl => '${Environment.feralFileAssetURL}/$coverURI';

  bool get isGroupExhibition => type == 'group';

  //TODO: implement this
  bool get isFreeToStream => true;

  //TODO: implement this
  bool get isOnGoing => true;
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
