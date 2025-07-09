part of 'playlists_bloc.dart';

// Base state class
abstract class PlaylistsState {
  const PlaylistsState({
    required this.playlists,
    required this.hasMore,
    required this.cursor,
  });
  final List<DP1Call> playlists;
  final bool hasMore;
  final String? cursor;
}

// Initial state
class PlaylistsInitialState extends PlaylistsState {
  const PlaylistsInitialState()
      : super(
          playlists: const [],
          hasMore: true,
          cursor: null,
        );
}

// Loading state (initial load)
class PlaylistsLoadingState extends PlaylistsState {
  const PlaylistsLoadingState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

// Loaded state
class PlaylistsLoadedState extends PlaylistsState {
  const PlaylistsLoadedState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

// Loading more state (pagination)
class PlaylistsLoadingMoreState extends PlaylistsState {
  const PlaylistsLoadingMoreState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

// Error state
class PlaylistsErrorState extends PlaylistsState {
  const PlaylistsErrorState({
    required this.error,
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
  final String error;
}
