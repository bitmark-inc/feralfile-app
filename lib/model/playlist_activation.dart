import 'package:autonomy_flutter/model/play_list_model.dart';

class PlaylistActivation {
  final String name;
  final String thumbnailURL;
  final String source;
  final PlayListModel playListModel;

  PlaylistActivation({
    required this.name,
    required this.thumbnailURL,
    required this.source,
    required this.playListModel,
  });
}
