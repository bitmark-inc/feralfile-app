import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';

class ViewPlaylistBloc extends AuBloc<ViewPlaylistEvent, ViewPlaylistState> {
  final PlaylistService _playlistService;

  ViewPlaylistBloc(this._playlistService, PlayListModel playlist)
      : super(ViewPlaylistState(playListModel: playlist)) {
    on<SavePlaylist>((event, emit) async {
      final playListModel = event.playlist;
      await _playlistService
          .setPlayList([playListModel], onConflict: ConflictAction.replace);

      emit(
        state.copyWith(
          playListModel: playListModel,
        ),
      );
    });
  }
}
