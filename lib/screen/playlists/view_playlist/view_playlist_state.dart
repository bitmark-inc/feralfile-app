import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class ViewPlaylistEvent {}

class SavePlaylist extends ViewPlaylistEvent {
  final PlayListModel playlist;

  SavePlaylist({required this.playlist});
}

class ViewPlaylistState {
  PlayListModel playListModel;

  ViewPlaylistState({
    required this.playListModel,
  });

  ViewPlaylistState copyWith({
    PlayListModel? playListModel,
  }) =>
      ViewPlaylistState(
        playListModel: playListModel ?? this.playListModel,
      );
}
