part of 'channels_bloc.dart';

// Base state class
abstract class ChannelsState {
  const ChannelsState({
    required this.channels,
    required this.hasMore,
    required this.cursor,
  });
  final List<Channel> channels;
  final bool hasMore;
  final String? cursor;
}

// Initial state
class ChannelsInitialState extends ChannelsState {
  const ChannelsInitialState()
      : super(
          channels: const [],
          hasMore: true,
          cursor: null,
        );
}

// Loading state (initial load)
class ChannelsLoadingState extends ChannelsState {
  const ChannelsLoadingState({
    required super.channels,
    required super.hasMore,
    required super.cursor,
  });
}

// Loaded state
class ChannelsLoadedState extends ChannelsState {
  const ChannelsLoadedState({
    required super.channels,
    required super.hasMore,
    required super.cursor,
  });
}

// Loading more state (pagination)
class ChannelsLoadingMoreState extends ChannelsState {
  const ChannelsLoadingMoreState({
    required super.channels,
    required super.hasMore,
    required super.cursor,
  });
}

// Error state
class ChannelsErrorState extends ChannelsState {
  const ChannelsErrorState({
    required this.error,
    required super.channels,
    required super.hasMore,
    required super.cursor,
  });
  final String error;
}
