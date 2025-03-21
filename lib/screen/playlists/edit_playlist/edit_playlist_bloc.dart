import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditPlaylistBloc extends Bloc<EditPlaylistEvent, EditPlaylistState> {
  EditPlaylistBloc() : super(EditPlaylistState()) {
    on<InitPlayList>((event, emit) {
      emit(
        EditPlaylistState(playListModel: event.playListModel, selectedItem: []),
      );
    });

    on<UpdateSelectedPlaylist>((event, emit) {
      if (event.value) {
        state.selectedItem?.add(event.tokenID);
      } else {
        state.selectedItem?.remove(event.tokenID);
      }
      final selectedItem = state.selectedItem?.toSet().toList();
      emit(state.copyWith(selectedItem: selectedItem));
    });

    on<SelectAllPlaylist>((event, emit) {
      if (event.value) {
        state.selectedItem = event.tokenIDs;
      } else {
        state.selectedItem = [];
      }
      final selectedItem = state.selectedItem?.toSet().toList();
      emit(state.copyWith(selectedItem: selectedItem));
    });

    on<UpdateOrderPlaylist>((event, emit) {
      final playlist = state.playListModel;
      playlist?.tokenIDs = event.tokenIDs ?? [];
      playlist?.thumbnailURL = event.thumbnailURL;
      emit(state.copyWith(playListModel: playlist));
    });

    on<RemoveTokens>((event, emit) {
      final playlist = state.playListModel;
      playlist?.tokenIDs
          .removeWhere((element) => event.tokenIDs?.contains(element) ?? false);
      emit(state.copyWith(playListModel: playlist, selectedItem: []));
    });

    on<UpdateNamePlaylist>((event, emit) {
      final playlist = state.playListModel;
      playlist?.name = event.name;
      emit(state.copyWith(playListModel: playlist));
    });

    on<SavePlaylist>((event, emit) async {
      final playListModel = state.playListModel;
      if (playListModel == null) {
        return;
      }
      playListModel.tokenIDs =
          state.playListModel?.tokenIDs.toSet().toList() ?? [];
      final service = injector.get<PlaylistService>();
      await service
          .setPlayList([playListModel], onConflict: ConflictAction.replace);
      emit(state.copyWith(isAddSuccess: true));
    });
  }
}
