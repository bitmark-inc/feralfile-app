import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';

class ChannelsService {
  ChannelsService(this.api);

  final DP1PlaylistApi api;

  Future<List<Channel>> getChannels({int page = 0, int limit = 10}) async {
    return api.getAllPlaylistGroups();
  }
}
