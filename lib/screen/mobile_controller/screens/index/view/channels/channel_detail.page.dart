import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/channel_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ChannelDetailPagePayload {
  ChannelDetailPagePayload({required this.channel});
  final Channel channel;
}

class ChannelDetailPage extends StatelessWidget {
  const ChannelDetailPage({required this.payload, super.key});
  final ChannelDetailPagePayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.auGreyBackground,
      appBar: detailPageAppBar(context, 'Channels'),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            ChannelItem(channel: payload.channel),
            const SizedBox(height: 40),
            _buildPlaylists(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylists(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Playlists',
            style: theme.textTheme.ppMori400White12,
          ),
        ],
      ),
    );
  }
}
