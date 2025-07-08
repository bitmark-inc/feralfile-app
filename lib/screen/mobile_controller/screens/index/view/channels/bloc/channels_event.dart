part of 'channels_bloc.dart';

// Base event class
abstract class ChannelsEvent {}

// Event to load initial channels
class LoadChannelsEvent extends ChannelsEvent {}

// Event to load more channels (pagination)
class LoadMoreChannelsEvent extends ChannelsEvent {}

// Event to refresh channels (pull to refresh)
class RefreshChannelsEvent extends ChannelsEvent {}