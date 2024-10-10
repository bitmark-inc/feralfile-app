import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:collection/collection.dart';

class AddNewPlaylistBloc
    extends AuBloc<AddNewPlaylistEvent, AddNewPlaylistState> {
  final PlaylistService _playListService;

  AddNewPlaylistBloc(this._playListService) : super(AddNewPlaylistState()) {
    on<InitPlaylist>((event, emit) {
      emit(
        AddNewPlaylistState(
          playListModel: event.playListModel ??
              PlayListModel(tokenIDs: [], thumbnailURL: '', name: ''),
          selectedIDs: List.from(event.playListModel?.tokenIDs ?? []),
        ),
      );
    });

    on<UpdateItemPlaylist>((event, emit) {
      if (event.value) {
        state.selectedIDs?.add(event.tokenID);
      } else {
        state.selectedIDs?.remove(event.tokenID);
      }
      state.selectedIDs = state.selectedIDs?.toSet().toList();
      emit(state.copyWith(selectedIDs: state.selectedIDs));
    });

    on<SelectItemPlaylist>((event, emit) {
      final listTokenIDs = state.tokens?.map((e) => e.id).toList() ?? [];
      if (event.isSelectAll) {
        state.selectedIDs = List.from(listTokenIDs);
      } else {
        state.selectedIDs?.clear();
      }
      state.selectedIDs = state.selectedIDs?.toSet().toList();
      emit(state.copyWith(selectedIDs: state.selectedIDs));
    });

    on<CreatePlaylist>((event, emit) async {
      final playListModel = state.playListModel;
      playListModel?.name = event.name;
      playListModel?.thumbnailURL = state.tokens
          ?.firstWhereOrNull(
              (element) => element.id == state.selectedIDs?.first)
          ?.getGalleryThumbnailUrl();

      playListModel?.tokenIDs = state.selectedIDs?.toSet().toList() ?? [];
      await _playListService
          .setPlayList([playListModel!], onConflict: ConflictAction.replace);

      emit(state.copyWith(isAddSuccess: true));
    });
  }
}
