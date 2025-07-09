import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';

class ChannelsService {
  ChannelsService(this.api, this.apiKey);

  final List<Channel> _channels = [];

  List<Channel> get cachedChannels => _channels;

  final DP1PlaylistApi api;
  final String apiKey;

  Future<DP1ChannelsResponse> getChannels({
    String? cursor,
    int? limit,
  }) async {
    final channels = await api.getAllPlaylistGroups(
      cursor: cursor,
      limit: limit,
    );
    channels.items.sort(
        (channel1, channel2) => channel1.created.compareTo(channel2.created));
    _channels.addAll(channels.items);
    return channels;
  }

  Future<Channel> createChannel(Channel channel) async {
    return api.createPlaylistGroup(channel.toJson(), 'Bearer $apiKey');
  }

  Future<Channel> getChannelDetail(String channelId) async {
    return api.getPlaylistGroupById(channelId);
  }
}
