import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

class ChannelsService {
  ChannelsService(this.api, this.apiKey);

  final List<Channel> _channels = [];

  List<String>? get remoteConfigChannelIds =>
      injector<RemoteConfigService>().getConfig<List<String>?>(
          ConfigGroup.dp1Playlist, ConfigKey.dp1PlaylistChannelIds, null);

  List<Channel> get cachedChannels => _channels
    ..removeWhere(
      (channel) => !(remoteConfigChannelIds?.contains(channel.id) ?? false),
    );

  final DP1PlaylistApi api;
  final String apiKey;

  Future<DP1ChannelsResponse> getChannels({
    String? cursor,
    int? limit,
  }) async {
    final List<Channel> listChannels = [];
    String? currentCursor = cursor;

    while (true) {
      final channels = await api.getAllPlaylistGroups(
        cursor: currentCursor,
        limit: limit,
      );
      currentCursor = channels.cursor;
      channels.items.sort(
          (channel1, channel2) => channel1.created.compareTo(channel2.created));
      channels.items.removeWhere(
        (channel) => !(remoteConfigChannelIds?.contains(channel.id) ?? true),
      );
      _channels.addAll(channels.items);
      listChannels.addAll(channels.items);
      if (!channels.hasMore || listChannels.length >= (limit ?? 100)) {
        return DP1ChannelsResponse(
          listChannels,
          channels.hasMore,
          channels.cursor,
        );
      }
    }
  }

  Future<Channel> createChannel(Channel channel) async {
    return api.createPlaylistGroup(channel.toJson(), 'Bearer $apiKey');
  }

  Future<Channel> getChannelDetail(String channelId) async {
    return api.getPlaylistGroupById(channelId);
  }
}
