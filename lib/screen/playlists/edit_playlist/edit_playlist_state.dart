// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class EditPlaylistEvent {}

class InitPlayList extends EditPlaylistEvent {
  PlayListModel? playListModel;

  InitPlayList({this.playListModel});
}

class UpdateSelectedPlaylist extends EditPlaylistEvent {
  final String tokenID;
  final bool value;

  UpdateSelectedPlaylist({required this.tokenID, required this.value});
}

class UpdateNamePlaylist extends EditPlaylistEvent {
  final String name;

  UpdateNamePlaylist({required this.name});
}

class SelectAllPlaylist extends EditPlaylistEvent {
  final bool value;
  final List<String>? tokenIDs;

  SelectAllPlaylist({required this.value, this.tokenIDs});
}

class SavePlaylist extends EditPlaylistEvent {
  SavePlaylist();
}

class UpdateOrderPlaylist extends EditPlaylistEvent {
  final List<String>? tokenIDs;
  final String? thumbnailURL;

  UpdateOrderPlaylist({required this.tokenIDs, this.thumbnailURL});
}

class RemoveTokens extends EditPlaylistEvent {
  final List<String>? tokenIDs;

  RemoveTokens({required this.tokenIDs});
}

class EditPlaylistState {
  PlayListModel? playListModel;
  List<String>? selectedItem;
  bool? isAddSuccess;

  EditPlaylistState({
    this.playListModel,
    this.selectedItem,
    this.isAddSuccess,
  });

  EditPlaylistState copyWith({
    PlayListModel? playListModel,
    List<String>? selectedItem,
    bool isAddSuccess = false,
  }) {
    return EditPlaylistState(
      playListModel: playListModel ?? this.playListModel,
      selectedItem: selectedItem ?? this.selectedItem,
      isAddSuccess: isAddSuccess,
    );
  }
}
