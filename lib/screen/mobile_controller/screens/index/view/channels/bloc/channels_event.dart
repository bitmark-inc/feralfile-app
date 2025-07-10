part of 'channels_bloc.dart';

abstract class ChannelsEvent {
  const ChannelsEvent();
}

class LoadChannelsEvent extends ChannelsEvent {
  const LoadChannelsEvent();
}

class LoadMoreChannelsEvent extends ChannelsEvent {
  const LoadMoreChannelsEvent();
}

class RefreshChannelsEvent extends ChannelsEvent {
  const RefreshChannelsEvent();
}
