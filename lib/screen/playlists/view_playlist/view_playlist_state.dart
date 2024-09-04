import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class ViewPlaylistEvent {}

class GetPlayList extends ViewPlaylistEvent {
  final PlayListModel? playListModel;

  GetPlayList({this.playListModel});
}

class ChangeRename extends ViewPlaylistEvent {
  final bool value;

  ChangeRename({required this.value});
}

class SavePlaylist extends ViewPlaylistEvent {
  final String? name;

  SavePlaylist({this.name});
}

class ViewPlaylistState {
  PlayListModel? playListModel;
  bool? isRename;

  ViewPlaylistState({
    this.playListModel,
    this.isRename,
  });

  ViewPlaylistState copyWith({
    PlayListModel? playListModel,
    bool? isRename,
  }) =>
      ViewPlaylistState(
        playListModel: playListModel ?? this.playListModel,
        isRename: isRename ?? this.isRename,
      );
}
