import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class AddNewPlaylistBloc
    extends Bloc<AddNewPlaylistEvent, AddNewPlaylistState> {
  final _configurationService = injector.get<ConfigurationService>();
  AddNewPlaylistBloc() : super(AddNewPlaylistState()) {
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
          ?.getThumbnailUrl(
            usingThumbnailID: false,
          );

      playListModel?.tokenIDs = state.selectedIDs?.toSet().toList();

      if (playListModel?.id == null) {
        playListModel?.id = const Uuid().v4();
        await _configurationService.setPlayList([playListModel!]);
        injector.get<SettingsDataService>().backup();
      }
      emit(state.copyWith(isAddSuccess: true));
      final metricClient = injector<MetricClientService>();
      metricClient.addEvent(MixpanelEvent.createPlaylist);
    });
  }
}
