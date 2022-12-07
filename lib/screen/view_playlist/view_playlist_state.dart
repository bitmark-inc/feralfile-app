import 'package:nft_collection/models/asset_token.dart';

import 'package:autonomy_flutter/model/play_list_model.dart';

abstract class ViewPlaylistEvent {}

class GetPlayList extends ViewPlaylistEvent {
  GetPlayList();
}

class ChangeRename extends ViewPlaylistEvent {
  final bool value;
  ChangeRename({required this.value});
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
  }) {
    return ViewPlaylistState(
      playListModel: playListModel ?? this.playListModel,
      isRename: isRename ?? this.isRename,
    );
  }
}
