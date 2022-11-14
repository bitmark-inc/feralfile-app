import 'package:autonomy_flutter/screen/edit_playlist/edit_playlist_state.dart';
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

    on<UpdateOrderPlaylist>((event, emit) {
      final playlist = state.playListModel;
      playlist?.tokenIDs = event.tokenIDs;
      emit(state.copyWith(playListModel: playlist));
    });

    on<RemoveTokens>((event, emit) {
      final playlist = state.playListModel;
      playlist?.tokenIDs?.removeWhere(
          (element) => event.tokenIDs?.contains(element) ?? false);
      emit(state.copyWith(playListModel: playlist, selectedItem: []));
    });
  }
}
