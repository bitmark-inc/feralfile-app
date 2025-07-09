part of 'channel_detail_bloc.dart';

abstract class ChannelDetailEvent {
  const ChannelDetailEvent({required this.channel});

  final Channel channel;
}

class LoadChannelPlaylistsEvent extends ChannelDetailEvent {
  LoadChannelPlaylistsEvent({required super.channel});
}

class LoadMoreChannelPlaylistsEvent extends ChannelDetailEvent {
  LoadMoreChannelPlaylistsEvent({required super.channel});
}

class RefreshChannelPlaylistsEvent extends ChannelDetailEvent {
  RefreshChannelPlaylistsEvent({required super.channel});
}
