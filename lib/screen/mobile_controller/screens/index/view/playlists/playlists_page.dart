import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/bloc/playlists_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/error_view.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/load_more_indicator.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/loading_view.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final PlaylistsBloc _playlistsBloc;

  @override
  void initState() {
    super.initState();
    _playlistsBloc = injector<PlaylistsBloc>();
    _scrollController.addListener(_onScroll);
    _playlistsBloc.add(LoadPlaylistsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _playlistsBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels + 100 >=
        _scrollController.position.maxScrollExtent) {
      _playlistsBloc.add(LoadMorePlaylistsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      bloc: _playlistsBloc,
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            _playlistsBloc.add(RefreshPlaylistsEvent());
            // Wait for the refresh to complete
            await _playlistsBloc.stream.firstWhere(
              (state) =>
                  state is PlaylistsLoadedState || state is PlaylistsErrorState,
            );
          },
          backgroundColor: AppColor.primaryBlack,
          color: AppColor.white,
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(PlaylistsState state) {
    if (state is PlaylistsLoadingState && state.playlists.isEmpty) {
      return const LoadingView();
    }

    if (state is PlaylistsErrorState && state.playlists.isEmpty) {
      return ErrorView(
        error: 'Error loading playlists: ${state.error}',
        onRetry: () => _playlistsBloc.add(LoadPlaylistsEvent()),
      );
    }

    return _buildPlaylistsList(state);
  }

  Widget _buildPlaylistsList(PlaylistsState state) {
    final playlists = state.playlists;
    final hasMore = state.hasMore;
    final isLoadingMore = state is PlaylistsLoadingMoreState;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: playlists.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == playlists.length) {
          return LoadMoreIndicator(isLoadingMore: isLoadingMore);
        }

        final playlist = playlists[index];
        final channel =
            injector<Dp1PlaylistService>().getChannelByPlaylistId(playlist.id);

        return Column(
          children: [
            PlaylistItem(
              playlist: playlist,
              channel: channel,
            ),
            if (index == playlists.length - 1) const SizedBox(height: 120),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
