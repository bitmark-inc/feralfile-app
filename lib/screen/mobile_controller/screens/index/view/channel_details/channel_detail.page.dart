import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channel_details/bloc/channel_detail_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/channel_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/loading_indicator.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChannelDetailPagePayload {
  ChannelDetailPagePayload({required this.channel});

  final Channel channel;
}

class ChannelDetailPage extends StatefulWidget {
  const ChannelDetailPage({required this.payload, super.key});

  final ChannelDetailPagePayload payload;

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  late final ChannelDetailBloc _channelDetailBloc;

  @override
  void initState() {
    super.initState();
    _channelDetailBloc = injector<ChannelDetailBloc>();
    _channelDetailBloc
        .add(LoadChannelPlaylistsEvent(channel: widget.payload.channel));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.auGreyBackground,
      appBar: DetailPageAppBar(title: 'Channels'),
      body: SafeArea(
        child: BlocBuilder<ChannelDetailBloc, ChannelDetailState>(
          bloc: _channelDetailBloc,
          builder: (context, state) {
            return Column(
              children: [
                const SizedBox(height: UIConstants.detailPageHeaderPadding),
                ChannelItem(channel: widget.payload.channel),
                const SizedBox(height: UIConstants.detailPageHeaderPadding),
                _buildPlaylists(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaylists(BuildContext context, ChannelDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state is ChannelDetailLoadedState)
          ...state.playlists.map(
            (playlist) => PlaylistItem(
              playlist: playlist,
              channel: widget.payload.channel,
            ),
          ),
        if (state is ChannelDetailLoadingState) const LoadingIndicator(),
        if (state is ChannelDetailErrorState) Center(child: Text(state.error)),
      ],
    );
  }
}
