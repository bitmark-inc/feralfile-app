import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

class Dp1PlaylistService {
  Dp1PlaylistService(this.api, this.apiKey);
  final DP1PlaylistApi api;
  final String apiKey;

  // PLAYLIST
  Future<DP1Call> createPlaylist(DP1Call playlist) async {
    return api.createPlaylist(playlist.toJson(), 'Bearer $apiKey');
  }

  Future<DP1Call> getPlaylistById(String playlistId) async {
    return api.getPlaylistById(playlistId);
  }

  Future<DP1PlaylistResponse> getPlaylists({
    String? cursor,
    int? limit,
  }) async {
    return api.getAllPlaylists(
      cursor: cursor,
      limit: limit,
    );
  }

  // PLAYLIST GROUP
  Future<Channel> createPlaylistGroup(Channel group) async {
    return api.createPlaylistGroup(group.toJson(), 'Bearer $apiKey');
  }

  Future<Channel> getPlaylistGroupById(String groupId) async {
    return api.getPlaylistGroupById(groupId);
  }

  Future<List<DP1Call>> getPlaylistsByChannel(Channel channel) async {
    final dio = Dio();
    final futures = channel.playlists.map((playlistUrl) async {
      try {
        final response = await dio.get<Map<String, dynamic>>(playlistUrl);
        if (response.statusCode == 200 && response.data != null) {
          return DP1Call.fromJson(response.data!);
        }
      } catch (e) {
        log.info('Error when get playlists from channel ${channel.title}: $e');
        return null;
      }
    });
    final results = await Future.wait(futures);
    return results.whereType<DP1Call>().toList();
  }
}
