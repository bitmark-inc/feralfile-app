import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';

class PlaylistCloudObject {
  PlaylistCloudObject(this._db);

  final CloudDB _db;

  Future<bool> deletePlaylists(List<PlayListModel> playlists) =>
      _db.delete(playlists.map((e) => e.key).toList());

  List<PlayListModel> getPlaylists() {
    final playlists = _db.values
        .map((e) =>
            PlayListModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    return playlists;
  }

  PlayListModel? getPlaylistById(String id) {
    final rawString = _db.query([id]).firstOrNull?['value'];
    if (rawString == null || rawString.isEmpty) {
      return null;
    }
    return PlayListModel.fromJson(
        jsonDecode(rawString) as Map<String, dynamic>);
  }

  Future<void> setPlaylists(List<PlayListModel> playlists) async {
    await _db.write(playlists.map((e) => e.toKeyValue).toList());
  }

  Future<void> download() async {
    await _db.download();
  }

  // clear cache
  void clearCache() {
    _db.clearCache();
  }
}
