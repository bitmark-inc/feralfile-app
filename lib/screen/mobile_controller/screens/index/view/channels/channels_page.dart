import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Channels page',
              style: theme.textTheme.ppMori400White12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
