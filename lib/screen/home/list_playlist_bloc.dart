import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class ListPlaylistEvent {}

class ListPlaylistLoadPlaylist extends ListPlaylistEvent {
  final String filter;
  final bool refreshDefaultPlaylist;

  ListPlaylistLoadPlaylist(
      {this.filter = '', this.refreshDefaultPlaylist = false});
}

class ListPlaylistState {
  final List<PlayListModel> playlists;

  ListPlaylistState({this.playlists = const []});
}

class ListPlaylistBloc extends AuBloc<ListPlaylistEvent, ListPlaylistState> {
  final _playlistService = injector.get<PlaylistService>();

  List<PlayListModel>? _defaultPlaylist;

  ListPlaylistBloc() : super(ListPlaylistState()) {
    on<ListPlaylistLoadPlaylist>((event, emit) async {
      log.info('ListPlaylistLoadPlaylist: ${event.filter}');
      final playlists = await _playlistService.getPlayList();
      if (event.refreshDefaultPlaylist || _defaultPlaylist == null) {
        _defaultPlaylist = await _playlistService.defaultPlaylists();
      }
      playlists.addAll(_defaultPlaylist!);

      emit(ListPlaylistState(playlists: playlists.filter(event.filter)));
      log.info('ListPlaylistLoadPlaylist: ${playlists.length}');
    });
  }
}
