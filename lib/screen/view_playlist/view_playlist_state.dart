import 'package:nft_collection/models/asset_token.dart';

import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class ViewPlaylistEvent {}

class GetPlayList extends ViewPlaylistEvent {
  GetPlayList();
}

class UpdateItemPlaylist extends ViewPlaylistEvent {
  final String tokenID;
  final bool value;
  UpdateItemPlaylist({required this.tokenID, required this.value});
}

class SelectItemPlaylist extends ViewPlaylistEvent {
  final bool isSelectAll;
  SelectItemPlaylist({required this.isSelectAll});
}

class CreatePlaylist extends ViewPlaylistEvent {
  final String? name;
  CreatePlaylist({required this.name});
}

class ViewPlaylistState {
  PlayListModel? playListModel;
  ViewPlaylistState({
    this.playListModel,
  });

  ViewPlaylistState copyWith({
    PlayListModel? playListModel,
  }) {
    return ViewPlaylistState(
      playListModel: playListModel ?? this.playListModel,
    );
  }
}
