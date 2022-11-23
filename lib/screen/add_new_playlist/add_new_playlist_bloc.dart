import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class AddNewPlaylistBloc
    extends Bloc<AddNewPlaylistEvent, AddNewPlaylistState> {
  final _configurationService = injector.get<ConfigurationService>();
  AddNewPlaylistBloc() : super(AddNewPlaylistState()) {
    on<InitPlaylist>((event, emit) {
      emit(
        AddNewPlaylistState(
          playListModel: event.playListModel ??
              PlayListModel(tokenIDs: [], thumbnailURL: '', name: ''),
        ),
      );
    });

    on<UpdateItemPlaylist>((event, emit) {
      final playListModel = state.playListModel;
      if (event.value) {
        playListModel?.tokenIDs?.add(event.tokenID);
      } else {
        playListModel?.tokenIDs?.remove(event.tokenID);
      }
      playListModel?.tokenIDs = state.playListModel?.tokenIDs?.toSet().toList();
      emit(state.copyWith(playListModel: playListModel));
    });

    on<SelectItemPlaylist>((event, emit) {
      final playListModel = state.playListModel;
      final hiddenTokens =
          injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
      final sentArtworks =
          injector<ConfigurationService>().getRecentlySentToken();
      final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

      final listTokenIDs = state.tokens
              ?.where(
                (element) =>
                    !hiddenTokens.contains(element.id) &&
                    !sentArtworks.any(
                      (e) => e.isHidden(
                          tokenID: element.id,
                          address: element.ownerAddress,
                          timestamp: expiredTime),
                    ),
              )
              .map((e) => e.id)
              .toList() ??
          [];
      if (event.isSelectAll) {
        playListModel?.tokenIDs = List.from(listTokenIDs);
      } else {
        playListModel?.tokenIDs?.clear();
      }
      playListModel?.tokenIDs = state.playListModel?.tokenIDs?.toSet().toList();
      emit(state.copyWith(playListModel: playListModel));
    });

    on<CreatePlaylist>((event, emit) async {
      final playListModel = state.playListModel;
      playListModel?.name = event.name;
      playListModel?.thumbnailURL = state.tokens
          ?.firstWhereOrNull(
              (element) => element.id == playListModel.tokenIDs?.first)
          ?.getGalleryThumbnailUrl();

      playListModel?.tokenIDs = state.playListModel?.tokenIDs?.toSet().toList();
      if (playListModel?.id == null) {
        playListModel?.id = const Uuid().v4();
        await _configurationService.setPlayList([playListModel!]);
        injector.get<SettingsDataService>().backup();
      }
      emit(state.copyWith(isAddSuccess: true));
    });
  }
}
