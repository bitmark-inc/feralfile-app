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
  @POST('/playlists')
  Future<DP1Call> createPlaylist(
    @Body() Map<String, dynamic> body,
    @Header('Authorization') String bearerToken,
  );

  @GET('/playlists/{playlistId}')
  Future<DP1Call> getPlaylistById(
    @Path('playlistId') String playlistId,
  );

  @GET('/playlists')
  Future<DP1PlaylistResponse> getAllPlaylists({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('sortBy') String? sortBy,
    @Query('sortOrder') String? sortOrder,
  });

  // PLAYLIST GROUP
  @POST('/playlist-groups')
  Future<Channel> createPlaylistGroup(
    @Body() Map<String, dynamic> body,
    @Header('Authorization') String bearerToken,
  );

  @GET('/playlist-groups/{groupId}')
  Future<Channel> getPlaylistGroupById(
    @Path('groupId') String groupId,
  );

  @GET('/playlist-groups')
  Future<DP1ChannelsResponse> getAllPlaylistGroups({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });
}
