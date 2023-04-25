// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';

import 'package:autonomy_flutter/screen/album/album_screen.dart';

abstract class AlbumState {}

abstract class AlbumEvent {}

class AlbumInitState extends AlbumState {}

class AlbumLoadedState extends AlbumState {
  final List<CompactedAssetToken>? assetTokens;
  final NftLoadingState nftLoadingState;

  AlbumLoadedState({
    this.assetTokens,
    required this.nftLoadingState,
  });

  AlbumLoadedState copyWith({
    List<CompactedAssetToken>? assetTokens,
    NftLoadingState? nftLoadingState,
  }) {
    return AlbumLoadedState(
      assetTokens: assetTokens ?? this.assetTokens,
      nftLoadingState: nftLoadingState ?? this.nftLoadingState,
    );
  }
}

class LoadAlbumEvent extends AlbumEvent {
  final String? id;
  final AlbumType type;
  LoadAlbumEvent({
    this.id,
    required this.type,
  });
}
