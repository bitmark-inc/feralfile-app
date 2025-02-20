import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';

abstract class AddNewPlaylistEvent {}

class InitPlaylist extends AddNewPlaylistEvent {
  final PlayListModel? playListModel;

  InitPlaylist({this.playListModel});
}

class UpdateItemPlaylist extends AddNewPlaylistEvent {
  final String tokenID;
  final bool value;

  UpdateItemPlaylist({required this.tokenID, required this.value});
}

class SelectItemPlaylist extends AddNewPlaylistEvent {
  final bool isSelectAll;

  SelectItemPlaylist({required this.isSelectAll});
}

class CreatePlaylist extends AddNewPlaylistEvent {
  final String? name;

  CreatePlaylist({required this.name});
}

class AddNewPlaylistState {
  List<CompactedAssetToken>? tokens;
  PlayListModel? playListModel;
  List<String>? selectedIDs;
  bool? isAddSuccess;

  AddNewPlaylistState({
    this.tokens,
    this.playListModel,
    this.selectedIDs,
    this.isAddSuccess,
  });

  AddNewPlaylistState copyWith({
    List<CompactedAssetToken>? tokens,
    PlayListModel? playListModel,
    List<String>? selectedIDs,
    bool isAddSuccess = false,
  }) =>
      AddNewPlaylistState(
        tokens: tokens ?? this.tokens,
        playListModel: playListModel ?? this.playListModel,
        isAddSuccess: isAddSuccess,
        selectedIDs: selectedIDs ?? this.selectedIDs,
      );
}
