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

class CreatePlaylist extends EditPlaylistEvent {
  final String? name;
  CreatePlaylist({required this.name});
}

class UpdateOrderPlaylist extends EditPlaylistEvent {
  final List<String>? tokenIDs;
  UpdateOrderPlaylist({required this.tokenIDs});
}

class RemoveTokens extends EditPlaylistEvent {
  final List<String>? tokenIDs;
  RemoveTokens({required this.tokenIDs});
}

class EditPlaylistState {
  PlayListModel? playListModel;
  List<String>? selectedItem;
  EditPlaylistState({
    this.playListModel,
    this.selectedItem,
  });

  EditPlaylistState copyWith({
    PlayListModel? playListModel,
    List<String>? selectedItem,
  }) {
    return EditPlaylistState(
      playListModel: playListModel ?? this.playListModel,
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }
}
