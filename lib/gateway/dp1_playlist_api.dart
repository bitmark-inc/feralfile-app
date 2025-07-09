import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'dp1_playlist_api.g.dart';

@RestApi(baseUrl: 'https://api.feed.feralfile.com')
abstract class DP1PlaylistApi {
  factory DP1PlaylistApi(Dio dio, {String baseUrl}) = _DP1PlaylistApi;

  // PLAYLIST
  @POST('/api/v1/playlists')
  Future<DP1Call> createPlaylist(
    @Body() Map<String, dynamic> body,
    @Header('Authorization') String bearerToken,
  );

  @GET('/api/v1/playlists/{playlistId}')
  Future<DP1Call> getPlaylistById(
    @Path('playlistId') String playlistId,
  );

  @GET('/api/v1/playlists')
  Future<DP1PlaylistResponse> getAllPlaylists({
    @Query('playlist-group') String? playlistGroupId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  // PLAYLIST GROUP
  @POST('/api/v1/playlist-groups')
  Future<Channel> createPlaylistGroup(
    @Body() Map<String, dynamic> body,
    @Header('Authorization') String bearerToken,
  );

  @GET('/api/v1/playlist-groups/{groupId}')
  Future<Channel> getPlaylistGroupById(
    @Path('groupId') String groupId,
  );

  @GET('/api/v1/playlist-groups')
  Future<DP1ChannelsResponse> getAllPlaylistGroups({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });
}
