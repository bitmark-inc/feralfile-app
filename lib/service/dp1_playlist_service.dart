import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/services/channels_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

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

  Future<List<DP1Call>> getAllPlaylistsFromAllChannel(
      {required int page, required int limit}) async {
    final channel = await injector<ChannelsService>().getChannels();

    // Execute all requests in parallel
    final futures = channel.map((c) async {
      try {
        return await getPlaylistsByChannel(c);
      } catch (e) {
        log.info('Error when get playlists from channel ${c.title}: $e');
        return <DP1Call>[]; // Return empty list on error
      }
    });

    final results = await Future.wait(futures);
    return results.expand((list) => list).toList();
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
