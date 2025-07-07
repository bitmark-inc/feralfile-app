import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/bloc/channels_bloc.dart';
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
      return _buildLoadingView();
    }

    if (state is ChannelsErrorState && state.channels.isEmpty) {
      return _buildErrorView(state.error);
    }

    return _buildChannelsList(state);
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColor.white,
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error loading channels',
            style: theme.textTheme.ppMori400White12,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.ppMori400Grey12,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _channelsBloc.add(LoadChannelsEvent()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(ChannelsState state) {
    final channels = state.channels;
    final hasMore = state.hasMore;
    final isLoadingMore = state is ChannelsLoadingMoreState;

    return ListView.separated(
      controller: _scrollController,
      itemCount: channels.length + (hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        if (index == channels.length) {
          return _buildLoadingIndicator(isLoadingMore);
        }

        return Column(
          children: [
            _buildChannelItem(channels[index]),
            if (index < channels.length - 1)
              const Divider(
                height: 1,
                color: AppColor.primaryBlack,
              ),
            if (index == channels.length - 1) const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator(bool isLoadingMore) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLoadingMore
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppColor.white,
                strokeWidth: 2,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildChannelItem(Channel channel) {
    final theme = Theme.of(context);

    return Container(
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
