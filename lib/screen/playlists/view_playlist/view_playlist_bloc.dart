import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';

class ViewPlaylistBloc extends AuBloc<ViewPlaylistEvent, ViewPlaylistState> {
  final PlaylistService _playlistService;

  ViewPlaylistBloc(this._playlistService) : super(ViewPlaylistState()) {
    on<GetPlayList>((event, emit) {
      emit(
        ViewPlaylistState(
          playListModel: event.playListModel ??
              PlayListModel(tokenIDs: [], thumbnailURL: '', name: ''),
        ),
      );
    });
    on<ChangeRename>((event, emit) {
      emit(state.copyWith(isRename: event.value));
    });

    on<SavePlaylist>((event, emit) async {
      final playListModel = state.playListModel;
      if (event.name != null) {
        playListModel?.name = event.name;
      }

      final playlists = await _playlistService.getPlayList();
      final index =
          playlists.indexWhere((element) => element.id == playListModel?.id);
      if (index != -1 && playListModel != null) {
        playlists[index] = playListModel;
        await _playlistService.setPlayList(playlists, override: true);
      }
      emit(state.copyWith(isRename: false));
    });
  }
}
