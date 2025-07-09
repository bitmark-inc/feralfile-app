import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';

class ChannelsService {
  ChannelsService(this.api);

  final List<Channel> _channels = [];

  List<Channel> get cachedChannels => _channels;

  final DP1PlaylistApi api;

  Future<DP1ChannelsResponse> getChannels({
    String? cursor,
    int? limit,
  }) async {
    final channels = await api.getAllPlaylistGroups(
      cursor: cursor,
      limit: limit,
    );
    _channels.addAll(channels.items);
    return channels;
  }
}
