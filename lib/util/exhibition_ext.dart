import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
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

  Artwork representArtwork(String seriesId) => artworks!.firstWhere(
      (e) => e.seriesID == seriesId && getArtworkTokenId(e) != null);

  List<Artwork> get representArtworks =>
      seriesIds.map((e) => representArtwork(e)).toList();

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
      final contract = exhibition.contracts!.firstWhereOrNull(
          (e) => e.blockchainType == exhibition.mintBlockchain);
      final contractAddress = contract?.address;
      if (contractAddress == null) {
        return null;
      }
      final id = artwork.id;
      return '$chain-$contract-$id';
    }
  }
}

// Artwork Ext
extension ArtworkExt on Artwork {
  String get thumbnailURL => '${Environment.feralFileAssetURL}/$thumbnailURI';
}

String? getFFUrl(String? uri) =>
    uri != null ? '${Environment.feralFileAssetURL}/$uri' : null;
