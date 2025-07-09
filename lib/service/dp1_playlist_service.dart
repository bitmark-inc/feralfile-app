import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/services/channels_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

class Dp1PlaylistService {
  Dp1PlaylistService(this.api, this.apiKey);

  final DP1PlaylistApi api;
  final String apiKey;

  final urlmap = <String, String>{};

  // PLAYLIST
  Future<DP1Call> createPlaylist(DP1Call playlist) async {
    return api.createPlaylist(playlist.toJson(), 'Bearer $apiKey');
  }

  Future<DP1Call> getPlaylistById(String playlistId) async {
    return api.getPlaylistById(playlistId);
  }

  Future<List<DP1Call>> getAllPlaylistsFromAllChannel() async {
    final response = await injector<ChannelsService>().getChannels();
    final channels = response.items;

    // Execute all requests in parallel
    final futures = channels.map((c) async {
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

  Channel? getChannelByPlaylistId(String playlistId) {
    final cachedChannels = injector<ChannelsService>().cachedChannels;
    for (final channel in cachedChannels) {
      for (final playlistUrl in channel.playlists) {
        if (urlmap[playlistId] == playlistUrl) {
          return channel;
        }
      }
    }
    return null;
  }

  Future<DP1PlaylistResponse> getPlaylists({
    String? cursor,
    int? limit,
  }) async {
    final playlists = await getAllPlaylistsFromAllChannel();
    final hasMore = false;
    return DP1PlaylistResponse(playlists, hasMore, null);

    // return api.getAllPlaylists(
    //   cursor: cursor,
    //   limit: limit,
    // );
  }

  // PLAYLIST GROUP
  Future<Channel> createPlaylistGroup(Channel group) async {
    return api.createPlaylistGroup(group.toJson(), 'Bearer $apiKey');
  }

  Future<Channel> getPlaylistGroupById(String groupId) async {
    return api.getPlaylistGroupById(groupId);
  }

  Future<List<DP1Call>> getPlaylistsByChannel(Channel channel) async {
    // map DP1Call Id to url
    final dio = Dio();
    final futures = channel.playlists.map((playlistUrl) async {
      try {
        final response = await dio.get<Map<String, dynamic>>(playlistUrl);
        if (response.statusCode == 200 && response.data != null) {
          final playlist = DP1Call.fromJson(response.data!);
          urlmap.putIfAbsent(playlist.id, () => playlistUrl);
          return playlist;
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
