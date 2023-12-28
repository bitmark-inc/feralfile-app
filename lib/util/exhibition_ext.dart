import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

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

  String representTokenId(String seriesId) {
    final artwork = artworks!.firstWhere((e) => e.seriesID == seriesId);
    return getArtworkTokenId(artwork);
  }

  Artwork representArtwork(String seriesId) =>
      artworks!.firstWhere((e) => e.seriesID == seriesId);

  String getArtworkTokenId(Artwork artwork) {
    if (artwork.swap != null) {
      final chain = artwork.swap!.blockchainType == 'ethereum' ? 'eth' : 'tez';
      final contract = artwork.swap!.contractAddress;
      final id = chain == 'eth'
          ? artwork.swap!.token.hexToDecimal
          : artwork.swap!.token;
      return '$chain-$contract-$id';
    } else {
      final chain = exhibition.mintBlockchain == 'ethereum' ? 'eth' : 'tez';
      final contract = exhibition.contracts!
          .firstWhere((e) => e.blockchainType == exhibition.mintBlockchain)
          .address;
      final id = artwork.id;
      return '$chain-$contract-$id';
    }
  }
}
