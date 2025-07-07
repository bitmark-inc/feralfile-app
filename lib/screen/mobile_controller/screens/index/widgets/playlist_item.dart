import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/extensions/dp1_call_ext.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PlaylistItem extends StatelessWidget {
  const PlaylistItem({required this.playlist, super.key});

  final DP1Call playlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed(
          AppRouter.playlistDetailsPage,
          arguments: playlist,
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                // Playlist info
                Expanded(
                  child: Text(
                    playlist.playlistName,
                    style: theme.textTheme.ppMori400White12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Feral File',
                  style: theme.textTheme.ppMori400Grey12.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: AppColor.primaryBlack,
          ),
        ],
      ),
    );
  }
}
