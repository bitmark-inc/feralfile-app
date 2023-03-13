import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewPlaylistBloc extends Bloc<ViewPlaylistEvent, ViewPlaylistState> {
  ViewPlaylistBloc() : super(ViewPlaylistState()) {
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
      playListModel?.name = event.name;
      final config = injector.get<ConfigurationService>();

      final playlists = config.getPlayList();
      final index =
          playlists?.indexWhere((element) => element.id == playListModel?.id) ??
              -1;
      if (index != -1 && playListModel != null) {
        playlists?[index] = playListModel;
        config.setPlayList(playlists, override: true);
        injector.get<SettingsDataService>().backup();
      }
      emit(state.copyWith(isRename: false));
    });

    on<UpdatePlayControl>((event, emit) async {
      final playListModel = state.playListModel;
      playListModel?.playControlModel = event.playControlModel;
      final config = injector.get<ConfigurationService>();

      final playlists = config.getPlayList();
      final index =
          playlists?.indexWhere((element) => element.id == playListModel?.id) ??
              -1;
      if (index != -1 && playListModel != null) {
        playlists?[index] = playListModel;
        config.setPlayList(playlists, override: true);
        injector.get<SettingsDataService>().backup();
      }
      emit(state.copyWith(playListModel: playListModel));
    });
  }
}
