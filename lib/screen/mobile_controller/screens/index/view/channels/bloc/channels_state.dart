part of 'channels_bloc.dart';

enum ChannelsStatus {
  initial,
  loading,
  loadingMore,
  loaded,
  error,
}

@immutable
class ChannelsState {
  const ChannelsState({
    this.status = ChannelsStatus.initial,
    this.channels = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final ChannelsStatus status;
  final List<Channel> channels;
  final bool hasMore;
  final String? cursor;
  final String? error;

  ChannelsState copyWith({
    ChannelsStatus? status,
    List<Channel>? channels,
    bool? hasMore,
    String? cursor,
    String? error,
  }) {
    return ChannelsState(
      status: status ?? this.status,
      channels: channels ?? this.channels,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelsState &&
        other.status == status &&
        other.channels == channels &&
        other.hasMore == hasMore &&
        other.cursor == cursor &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        channels.hashCode ^
        hasMore.hashCode ^
        cursor.hashCode ^
        error.hashCode;
  }

  bool get isInitial => status == ChannelsStatus.initial;
  bool get isLoading => status == ChannelsStatus.loading;
  bool get isLoadingMore => status == ChannelsStatus.loadingMore;
  bool get isLoaded => status == ChannelsStatus.loaded;
  bool get isError => status == ChannelsStatus.error;
}
