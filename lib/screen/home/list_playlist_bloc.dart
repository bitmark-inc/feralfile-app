import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class ListPlaylistEvent {}

class ListPlaylistLoadPlaylist extends ListPlaylistEvent {
  final String filter;

  ListPlaylistLoadPlaylist({this.filter = ''});
}

class ListPlaylistState {
  final List<PlayListModel> playlists;

  ListPlaylistState({this.playlists = const []});
}

class ListPlaylistBloc extends AuBloc<ListPlaylistEvent, ListPlaylistState> {
  final _playlistService = injector.get<PlaylistService>();

  ListPlaylistBloc() : super(ListPlaylistState()) {
    on<ListPlaylistLoadPlaylist>((event, emit) async {
      log.info('ListPlaylistLoadPlaylist: ${event.filter}');
      List<PlayListModel> playlists = await _playlistService.getPlayList();
      final defaultPlaylists = await _playlistService.defaultPlaylists();
      playlists.addAll(defaultPlaylists);

      emit(ListPlaylistState(playlists: playlists.filter(event.filter)));
      log.info('ListPlaylistLoadPlaylist: ${playlists.length}');
    });
  }

  Future<List<PlayListModel>?> getPlaylist({bool withDefault = false}) async {
    List<PlayListModel> playlists = await _playlistService.getPlayList();
    if (withDefault) {
      final defaultPlaylists = await _playlistService.defaultPlaylists();
      playlists = defaultPlaylists..addAll(playlists);
    }
    return playlists;
  }
}
