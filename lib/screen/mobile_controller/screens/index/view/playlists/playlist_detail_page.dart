import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:feralfile_app_theme/style/colors.dart';
import 'package:flutter/material.dart';

class PlaylistDetailPagePayload {
  PlaylistDetailPagePayload({required this.playlist});
  final DP1Call playlist;
}

class PlaylistDetailPage extends StatelessWidget {
  const PlaylistDetailPage({required this.payload, super.key});
  final PlaylistDetailPagePayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.auGreyBackground,
      appBar: detailPageAppBar(context, 'Playlists'),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            PlaylistItem(playlist: payload.playlist),
            const SizedBox(height: 40),
            Expanded(
              child: _buildPlaylistWorks(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistWorks(BuildContext context) {
    return const Center(
      child: Text('Works grid'),
    );
  }
}
