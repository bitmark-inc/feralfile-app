import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/extensions/dp1_call_ext.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_event.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_state.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DP1PlaylistDetailsScreen extends StatelessWidget {
  const DP1PlaylistDetailsScreen({required this.playlist, super.key});

  final DP1Call playlist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistDetailsBloc(
        injector(),
        playlist,
      )..add(GetPlaylistDetailsEvent()),
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            Navigator.pop(context);
          },
          isWhite: false,
          statusBarColor: AppColor.auGreyBackground,
        ),
        backgroundColor: AppColor.auGreyBackground,
        body: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: UIConstants.topControlsBarHeight,
        ),
        _header(context),
        const Expanded(
          child: PlaylistAssetGridView(),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final playlist = this.playlist;
    return Column(
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
                playlist.channelName,
                style: theme.textTheme.ppMori400Grey12.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        addOnlyDivider(color: AppColor.primaryBlack),
      ],
    );
  }
}

class PlaylistAssetGridView extends StatefulWidget {
  const PlaylistAssetGridView({super.key});

  @override
  State<PlaylistAssetGridView> createState() => _PlaylistAssetGridViewState();
}

class _PlaylistAssetGridViewState extends State<PlaylistAssetGridView> {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final bloc = context.read<PlaylistDetailsBloc>();
      final state = bloc.state;
      if (state.hasMore && state is! PlaylistDetailsLoadingMoreState) {
        _isLoadingMore = true;
        bloc.add(LoadMorePlaylistDetailsEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistDetailsBloc, PlaylistDetailsState>(
      listener: (context, state) {
        if (state is! PlaylistDetailsLoadingMoreState) {
          _isLoadingMore = false;
        }
      },
      builder: (context, state) {
        if (state is PlaylistDetailsInitialState ||
            state is PlaylistDetailsLoadingState) {
          return _loadingView(context);
        }
        if (state.assetTokens.isEmpty) {
          return _emptyView(context);
        }
        return CustomScrollView(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 188 / 307,
                crossAxisSpacing: 17,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final asset = state.assetTokens[index];
                  final border = Border(
                    top: const BorderSide(
                      color: AppColor.auGreyBackground,
                    ),
                    right: BorderSide(
                      color: index.isEven
                          ? AppColor.auGreyBackground
                          : Colors.transparent,
                    ),
                    bottom: index >= state.assetTokens.length - 2
                        ? const BorderSide(
                            color: AppColor.auGreyBackground,
                          )
                        : BorderSide.none,
                  );
                  return GestureDetector(
                    child: _item(context, asset, border),
                    onTap: () {
                      injector<NavigationService>().navigateTo(
                        AppRouter.artworkDetailsPage,
                        arguments: ArtworkDetailPayload(
                          ArtworkIdentity(asset.id, asset.owner),
                          useIndexer: true,
                        ),
                      );
                    },
                  );
                },
                childCount: state.assetTokens.length,
              ),
            ),
            if (state is PlaylistDetailsLoadingMoreState)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _loadingView(BuildContext context) => const LoadingWidget(
        backgroundColor: AppColor.auGreyBackground,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 60),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 60),
      child: Text('Playlist Empty', style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _item(BuildContext context, AssetToken asset, Border border) {
    final title = asset.projectMetadata?.latest.title ?? asset.id;
    final artist = asset.projectMetadata?.latest.artistName ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: FFCacheNetworkImage(
              imageUrl: asset.galleryThumbnailURL ?? '',
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.ppMori400White12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                artist,
                style: Theme.of(context).textTheme.ppMori400Grey12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
