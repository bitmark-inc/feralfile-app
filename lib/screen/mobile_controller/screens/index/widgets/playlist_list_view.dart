import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/load_more_indicator.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:flutter/material.dart';

class PlaylistListView extends StatelessWidget {
  const PlaylistListView({
    required this.playlists,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    this.channel,
    this.isCustomTitle = false,
    this.channelVisible = true,
    super.key,
  });

  final List<DP1Call> playlists;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final Channel? channel;
  final bool isCustomTitle;
  final bool channelVisible;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      itemCount: playlists.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == playlists.length) {
          return Column(
            children: [
              LoadMoreIndicator(isLoadingMore: isLoadingMore),
              const SizedBox(height: 120),
            ],
          );
        }

        final playlist = playlists[index];

        return Column(
          children: [
            PlaylistItem(
              playlist: playlist,
              channel: channel,
              isCustomTitle: isCustomTitle,
              channelVisible: channelVisible,
            ),
            if (index == playlists.length - 1 && !hasMore)
              const SizedBox(
                height: 120,
              ),
          ],
        );
      },
    );
  }
}
