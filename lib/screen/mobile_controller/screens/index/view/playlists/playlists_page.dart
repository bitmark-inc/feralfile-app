import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/bloc/playlists_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/loading-indicator.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
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
      return const LoadingIndicator();
    }

    if (state is PlaylistsErrorState && state.playlists.isEmpty) {
      return _buildErrorView(state.error);
    }

    return _buildPlaylistsList(state);
  }

  Widget _buildErrorView(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error loading playlists',
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
            onPressed: () => _playlistsBloc.add(LoadPlaylistsEvent()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsList(PlaylistsState state) {
    final playlists = state.playlists;
    final hasMore = state.hasMore;
    final isLoadingMore = state is PlaylistsLoadingMoreState;

    return ListView.builder(
      controller: _scrollController,
      itemCount: playlists.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == playlists.length) {
          return _buildLoadingIndicator(isLoadingMore);
        }

        return Column(
          children: [
            _buildPlaylistItem(playlists[index]),
            if (index < playlists.length - 1)
              const Divider(
                height: 1,
                color: AppColor.primaryBlack,
              ),
            if (index == playlists.length - 1) const SizedBox(height: 20),
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

  Widget _buildPlaylistItem(DP1Call playlist) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        injector<NavigationService>()
            .navigateTo(AppRouter.playlistDetailsPage, arguments: playlist);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        color: Colors.transparent,
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
            Text(
              'Feral File',
              style: theme.textTheme.ppMori400Grey12.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
