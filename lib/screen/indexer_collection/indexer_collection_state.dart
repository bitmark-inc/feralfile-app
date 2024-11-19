import 'package:nft_collection/models/asset_token.dart';

class IndexerCollectionEvent {}

class IndexerCollectionGetCollectionEvent extends IndexerCollectionEvent {
  final String collectionId;

  IndexerCollectionGetCollectionEvent(this.collectionId);
}

class IndexerCollectionState {
  final List<AssetToken>? assetTokens;
  final double thumbnailRatio;

  IndexerCollectionState({
    this.assetTokens,
    this.thumbnailRatio = 1.0,
  });

  IndexerCollectionState copyWith({
    List<AssetToken>? assetTokens,
    double? thumbnailRatio,
  }) =>
      IndexerCollectionState(
        assetTokens: assetTokens ?? this.assetTokens,
        thumbnailRatio: thumbnailRatio ?? this.thumbnailRatio,
      );
}
