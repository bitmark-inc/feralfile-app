import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';

class ChannelsService {
  ChannelsService(this.api);

  final DP1PlaylistApi api;

  Future<DP1ChannelsResponse> getChannels({
    String? cursor,
    int? limit,
  }) async {
    return api.getAllPlaylistGroups(
      cursor: cursor,
      limit: limit,
    );
  }
}
