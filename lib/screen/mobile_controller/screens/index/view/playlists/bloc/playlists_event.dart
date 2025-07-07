part of 'playlists_bloc.dart';

// Base event class
abstract class PlaylistsEvent {}

// Event to load initial playlists
class LoadPlaylistsEvent extends PlaylistsEvent {}

// Event to load more playlists (pagination)
class LoadMorePlaylistsEvent extends PlaylistsEvent {}

// Event to refresh playlists (pull to refresh)
class RefreshPlaylistsEvent extends PlaylistsEvent {}
