part of 'playlists_bloc.dart';

enum PlaylistsStatus {
  initial,
  loading,
  loadingMore,
  loaded,
  error,
}

@immutable
class PlaylistsState {
  const PlaylistsState({
    this.status = PlaylistsStatus.initial,
    this.playlists = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final PlaylistsStatus status;
  final List<DP1Call> playlists;
  final bool hasMore;
  final String? cursor;
  final String? error;

  PlaylistsState copyWith({
    PlaylistsStatus? status,
    List<DP1Call>? playlists,
    bool? hasMore,
    String? cursor,
    String? error,
  }) {
    return PlaylistsState(
      status: status ?? this.status,
      playlists: playlists ?? this.playlists,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistsState &&
        other.status == status &&
        other.playlists == playlists &&
        other.hasMore == hasMore &&
        other.cursor == cursor &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        playlists.hashCode ^
        hasMore.hashCode ^
        cursor.hashCode ^
        error.hashCode;
  }

  bool get isInitial => status == PlaylistsStatus.initial;
  bool get isLoading => status == PlaylistsStatus.loading;
  bool get isLoadingMore => status == PlaylistsStatus.loadingMore;
  bool get isLoaded => status == PlaylistsStatus.loaded;
  bool get isError => status == PlaylistsStatus.error;
}
