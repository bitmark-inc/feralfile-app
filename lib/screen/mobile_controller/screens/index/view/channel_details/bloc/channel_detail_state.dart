part of 'channel_detail_bloc.dart';

enum ChannelDetailStatus {
  initial,
  loading,
  loadingMore,
  loaded,
  error,
}

@immutable
class ChannelDetailState {
  const ChannelDetailState({
    this.status = ChannelDetailStatus.initial,
    this.playlists = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final ChannelDetailStatus status;
  final List<DP1Call> playlists;
  final bool hasMore;
  final String? cursor;
  final String? error;

  ChannelDetailState copyWith({
    ChannelDetailStatus? status,
    List<DP1Call>? playlists,
    bool? hasMore,
    String? cursor,
    String? error,
  }) {
    return ChannelDetailState(
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
    return other is ChannelDetailState &&
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

  bool get isInitial => status == ChannelDetailStatus.initial;
  bool get isLoading => status == ChannelDetailStatus.loading;
  bool get isLoadingMore => status == ChannelDetailStatus.loadingMore;
  bool get isLoaded => status == ChannelDetailStatus.loaded;
  bool get isError => status == ChannelDetailStatus.error;
}
