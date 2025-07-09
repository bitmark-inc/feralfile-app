import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channel_details/channel_detail.page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/bloc/channels_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/channel_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/error_view.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/load_more_indicator.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/loading_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final ChannelsBloc _channelsBloc;

  @override
  void initState() {
    super.initState();
    _channelsBloc = injector<ChannelsBloc>();
    _scrollController.addListener(_onScroll);
    _channelsBloc.add(LoadChannelsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _channelsBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels + 100 >=
        _scrollController.position.maxScrollExtent) {
      _channelsBloc.add(LoadMoreChannelsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ChannelsBloc, ChannelsState>(
      bloc: _channelsBloc,
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            _channelsBloc.add(RefreshChannelsEvent());
            // Wait for the refresh to complete
            await _channelsBloc.stream.firstWhere(
              (state) =>
                  state is ChannelsLoadedState || state is ChannelsErrorState,
            );
          },
          backgroundColor: AppColor.primaryBlack,
          color: AppColor.white,
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(ChannelsState state) {
    if (state is ChannelsLoadingState && state.channels.isEmpty) {
      return const LoadingView();
    }

    if (state is ChannelsErrorState && state.channels.isEmpty) {
      return ErrorView(
        error: 'Error loading channels: ${state.error}',
        onRetry: () => _channelsBloc.add(LoadChannelsEvent()),
      );
    }

    return _buildChannelsList(state);
  }

  Widget _buildChannelsList(ChannelsState state) {
    final channels = state.channels;
    final hasMore = state.hasMore;
    final isLoadingMore = state is ChannelsLoadingMoreState;

    return ListView.custom(
      controller: _scrollController,
      childrenDelegate: SliverChildListDelegate([
        for (final channel in channels)
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.channelDetailPage,
                arguments: ChannelDetailPagePayload(channel: channel),
              );
            },
            child: ColoredBox(
              color: Colors.transparent,
              child: ChannelItem(channel: channel),
            ),
          ),
        if (hasMore) ...[
          const SizedBox(height: 20),
          LoadMoreIndicator(isLoadingMore: isLoadingMore),
        ],
        Container(
          height: 160,
        ),
      ]),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
