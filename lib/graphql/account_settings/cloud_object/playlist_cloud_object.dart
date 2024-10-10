import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';

class PlaylistCloudObject {
  final AccountSettingsDB _db;

  PlaylistCloudObject(this._db);

  AccountSettingsDB get db => _db;

  Future<bool> deletePlaylists(List<PlayListModel> playlists) =>
      _db.delete(playlists.map((e) => e.key).toList());

  List<PlayListModel> getPlaylists() {
    final playlists =
        _db.values.map((e) => PlayListModel.fromJson(jsonDecode(e))).toList();
    return playlists;
  }

  PlayListModel? getPlaylistById(String id) {
    final rawString = _db.allInstance[id];
    if (rawString == null || rawString.isEmpty) {
      return null;
    }
    return PlayListModel.fromJson(jsonDecode(rawString));
  }

  Future<void> setPlaylists(List<PlayListModel> playlists) async {
    await _db.write(playlists.map((e) => e.toKeyValue).toList());
  }
}
