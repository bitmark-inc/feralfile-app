import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:nft_collection/models/asset_token.dart';

class ExhibitionDetailEvent {}

class ExhibitionDetailState {
  ExhibitionDetailState({
    this.exhibition,
    this.assetTokens = const [],
  });

  final Exhibition? exhibition;
  final List<AssetToken> assetTokens;

  ExhibitionDetailState copyWith({
    Exhibition? exhibition,
    List<AssetToken>? assetTokens,
  }) =>
      ExhibitionDetailState(
        exhibition: exhibition ?? this.exhibition,
        assetTokens: assetTokens ?? this.assetTokens,
      );
}
