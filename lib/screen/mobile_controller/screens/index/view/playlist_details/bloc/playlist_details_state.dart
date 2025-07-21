import 'package:autonomy_flutter/nft_collection/models/models.dart';

abstract class PlaylistDetailsState {
  const PlaylistDetailsState({
    required this.assetTokens,
    required this.hasMore,
    required this.currentPage,
  });
  final List<AssetToken> assetTokens;
  final bool hasMore;
  final int currentPage;

  PlaylistDetailsState copyWith({
    List<AssetToken>? assetTokens,
    bool? hasMore,
    int? currentPage,
  }) {
    return PlaylistDetailsLoadedState(
      assetTokens: assetTokens ?? this.assetTokens,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [assetTokens, hasMore, currentPage];
}

class PlaylistDetailsInitialState extends PlaylistDetailsState {
  const PlaylistDetailsInitialState()
      : super(assetTokens: const [], hasMore: true, currentPage: 0);
}

class PlaylistDetailsLoadingState extends PlaylistDetailsState {
  const PlaylistDetailsLoadingState({
    required super.assetTokens,
    required super.hasMore,
    required super.currentPage,
  });
}

class PlaylistDetailsLoadedState extends PlaylistDetailsState {
  const PlaylistDetailsLoadedState({
    required super.assetTokens,
    required super.hasMore,
    required super.currentPage,
  });
}

class PlaylistDetailsLoadingMoreState extends PlaylistDetailsState {
  const PlaylistDetailsLoadingMoreState({
    required super.assetTokens,
    required super.hasMore,
    required super.currentPage,
  });
}

class PlaylistDetailsErrorState extends PlaylistDetailsState {
  const PlaylistDetailsErrorState({
    required this.error,
    required super.assetTokens,
    required super.hasMore,
    required super.currentPage,
  });
  final String error;

  @override
  List<Object?> get props => super.props..add(error);
}
