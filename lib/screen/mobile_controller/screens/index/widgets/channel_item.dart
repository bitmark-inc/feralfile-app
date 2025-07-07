import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/channel_detail.page.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ChannelItem extends StatelessWidget {
  const ChannelItem({required this.channel, super.key});
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.channelDetailPage,
          arguments: ChannelDetailPagePayload(channel: channel),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.title,
                  style: theme.textTheme.ppMori400White12,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  channel.description,
                  style: theme.textTheme.ppMori400Grey12,
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
