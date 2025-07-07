import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';

class Dp1PlaylistService {
  final DP1PlaylistApi api;
  final String apiKey;

  Dp1PlaylistService(this.api, this.apiKey);

  // PLAYLIST
  Future<DP1Call> createPlaylist(DP1Call playlist) async {
    return api.createPlaylist(playlist.toJson(), 'Bearer $apiKey');
  }

  Future<DP1Call> getPlaylistById(String playlistId) async {
    return api.getPlaylistById(playlistId);
  }

  Future<List<DP1Call>> getAllPlaylists() async {
    return api.getAllPlaylists();
  }

  // PLAYLIST GROUP
  Future<Channel> createPlaylistGroup(Channel group) async {
    return api.createPlaylistGroup(group.toJson(), 'Bearer $apiKey');
  }

  Future<Channel> getPlaylistGroupById(String groupId) async {
    return api.getPlaylistGroupById(groupId);
  }

  Future<List<Channel>> getAllPlaylistGroups() async {
    return api.getAllPlaylistGroups();
  }
}
