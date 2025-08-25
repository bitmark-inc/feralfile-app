part of 'channel_detail_bloc.dart';

abstract class ChannelDetailEvent {
  const ChannelDetailEvent();
}

class LoadChannelPlaylistsEvent extends ChannelDetailEvent {
  const LoadChannelPlaylistsEvent();
}

class LoadMoreChannelPlaylistsEvent extends ChannelDetailEvent {
  const LoadMoreChannelPlaylistsEvent();
}

class RefreshChannelPlaylistsEvent extends ChannelDetailEvent {
  const RefreshChannelPlaylistsEvent();
}
