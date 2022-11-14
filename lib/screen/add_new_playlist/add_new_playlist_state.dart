import 'package:nft_collection/models/asset_token.dart';

import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class AddNewPlaylistEvent {}

class InitPlaylist extends AddNewPlaylistEvent {
  InitPlaylist();
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
  List<AssetToken>? tokens;
  PlayListModel? playListModel;
  bool? isAddSuccess;
  AddNewPlaylistState({
    this.tokens,
    this.playListModel,
    this.isAddSuccess,
  });

  AddNewPlaylistState copyWith({
    List<AssetToken>? tokens,
    PlayListModel? playListModel,
    bool isAddSuccess = false,
  }) {
    return AddNewPlaylistState(
      tokens: tokens ?? this.tokens,
      playListModel: playListModel ?? this.playListModel,
      isAddSuccess: isAddSuccess,
    );
  }
}
