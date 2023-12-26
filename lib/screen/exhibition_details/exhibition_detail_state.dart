import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:nft_collection/models/asset_token.dart';

class ExhibitionDetailEvent {}

class SaveExhibitionEvent extends ExhibitionDetailEvent {
  SaveExhibitionEvent(this.exhibition);

  final Exhibition exhibition;
}

class GetArtworksEvent extends ExhibitionDetailEvent {}

class ExhibitionDetailState {
  ExhibitionDetailState({
    this.exhibition,
    this.assetTokens = const [],
    this.artworks = const [],
  });

  final Exhibition? exhibition;
  final List<AssetToken> assetTokens;
  final List<Artwork> artworks;

  ExhibitionDetailState copyWith({
    Exhibition? exhibition,
    List<AssetToken>? assetTokens,
    List<Artwork>? artworks,
  }) =>
      ExhibitionDetailState(
        exhibition: exhibition ?? this.exhibition,
        assetTokens: assetTokens ?? this.assetTokens,
        artworks: artworks ?? this.artworks,
      );
}
