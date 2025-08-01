import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channel_details/channel_detail.page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/dp1_playlist_details.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PlaylistItem extends StatelessWidget {
  const PlaylistItem({
    required this.playlist,
    this.channel,
    this.isCustomTitle = false,
    this.deviderColor = AppColor.primaryBlack,
    this.channelVisible = true,
    super.key,
  });

  final DP1Call playlist;
  final Channel? channel;
  final bool isCustomTitle;
  final Color deviderColor;
  final bool channelVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        injector<NavigationService>().navigateTo(
          AppRouter.playlistDetailsPage,
          arguments: DP1PlaylistDetailsScreenPayload(
            playlist: playlist,
            backTitle: isCustomTitle ? channel?.title : null,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveLayout.paddingHorizontal,
              vertical: 16,
            ),
            child: Row(
              children: [
                // Playlist info
                Expanded(
                  child: Text(
                    playlist.title,
                    style: theme.textTheme.ppMori400White12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (channel != null && channelVisible)
                  GestureDetector(
                    onTap: () {
                      injector<NavigationService>().navigateTo(
                        AppRouter.channelDetailPage,
                        arguments: ChannelDetailPagePayload(
                          channel: channel!,
                          backTitle: 'Playlists',
                        ),
                      );
                    },
                    child: Text(
                      channel!.title,
                      style: theme.textTheme.ppMori400Grey12.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: deviderColor,
          ),
        ],
      ),
    );
  }
}
