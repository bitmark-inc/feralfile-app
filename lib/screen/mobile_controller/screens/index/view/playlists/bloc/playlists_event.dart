part of 'playlists_bloc.dart';

abstract class PlaylistsEvent {
  const PlaylistsEvent();
}

class LoadPlaylistsEvent extends PlaylistsEvent {
  const LoadPlaylistsEvent();
}

class LoadMorePlaylistsEvent extends PlaylistsEvent {
  const LoadMorePlaylistsEvent();
}

class RefreshPlaylistsEvent extends PlaylistsEvent {
  const RefreshPlaylistsEvent();
}
