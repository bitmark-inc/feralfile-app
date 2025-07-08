part of 'channel_detail_bloc.dart';

abstract class ChannelDetailState {
  const ChannelDetailState({
    this.playlists = const [],
  });
  final List<DP1Call> playlists;
}

class ChannelDetailInitialState extends ChannelDetailState {
  const ChannelDetailInitialState();
}

class ChannelDetailLoadingState extends ChannelDetailState {
  const ChannelDetailLoadingState();
}

class ChannelDetailLoadedState extends ChannelDetailState {
  const ChannelDetailLoadedState({
    required super.playlists,
  });
}

class ChannelDetailErrorState extends ChannelDetailState {
  const ChannelDetailErrorState({
    required this.error,
  });
  final String error;
}
