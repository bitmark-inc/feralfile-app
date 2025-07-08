part of 'channel_detail_bloc.dart';

abstract class ChannelDetailEvent {}

class LoadChannelPlaylistsEvent extends ChannelDetailEvent {
  LoadChannelPlaylistsEvent({required this.channel});

  final Channel channel;
}
