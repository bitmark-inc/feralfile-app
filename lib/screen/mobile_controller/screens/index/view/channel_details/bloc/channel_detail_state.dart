part of 'channel_detail_bloc.dart';

abstract class ChannelDetailState {
  const ChannelDetailState({
    this.playlists = const [],
    this.hasMore = false,
    this.cursor,
  });
  final List<DP1Call> playlists;
  final bool hasMore;
  final String? cursor;
}

class ChannelDetailInitialState extends ChannelDetailState {
  const ChannelDetailInitialState()
      : super(
          playlists: const [],
          hasMore: true,
          cursor: null,
        );
}

class ChannelDetailLoadingState extends ChannelDetailState {
  const ChannelDetailLoadingState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

class ChannelDetailLoadedState extends ChannelDetailState {
  const ChannelDetailLoadedState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

class ChannelDetailLoadingMoreState extends ChannelDetailState {
  const ChannelDetailLoadingMoreState({
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
}

class ChannelDetailErrorState extends ChannelDetailState {
  const ChannelDetailErrorState({
    required this.error,
    required super.playlists,
    required super.hasMore,
    required super.cursor,
  });
  final String error;
}
