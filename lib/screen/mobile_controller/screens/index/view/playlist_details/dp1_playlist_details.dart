import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/intent.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_event.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_state.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/load_more_indicator.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DP1PlaylistDetailsScreenPayload {
  const DP1PlaylistDetailsScreenPayload({
    required this.playlist,
    this.backTitle,
  });

  final DP1Call playlist;
  final String? backTitle;
}

class DP1PlaylistDetailsScreen extends StatefulWidget {
  const DP1PlaylistDetailsScreen({required this.payload, super.key});

  final DP1PlaylistDetailsScreenPayload payload;

  @override
  State<DP1PlaylistDetailsScreen> createState() =>
      _DP1PlaylistDetailsScreenState();
}

class _DP1PlaylistDetailsScreenState extends State<DP1PlaylistDetailsScreen> {
  CanvasDeviceBloc get _canvasDeviceBloc => injector<CanvasDeviceBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: _canvasDeviceBloc,
      builder: (context, state) {
        return Scaffold(
          appBar: DetailPageAppBar(
            title: widget.payload.backTitle ?? 'Playlists',
            actions: [
              FFCastButton(
                displayKey: widget.payload.playlist.id,
                onDeviceSelected: (device) {
                  _canvasDeviceBloc.add(
                    CanvasDeviceCastDP1PlaylistEvent(
                      device: device,
                      playlist: widget.payload.playlist,
                      intent: DP1Intent.displayNow(),
                    ),
                  );
                },
              )
            ],
          ),
          backgroundColor: AppColor.auGreyBackground,
          body: _body(context),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final channel = injector<Dp1PlaylistService>()
        .getChannelByPlaylistId(widget.payload.playlist.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: PlaylistAssetGridView(
            header: Column(
              children: [
                const SizedBox(height: UIConstants.detailPageHeaderPadding),
                PlaylistItem(
                  playlist: widget.payload.playlist,
                  channel: channel,
                  clickable: false,
                )
              ],
            ),
            playlist: widget.payload.playlist,
            padding: const EdgeInsets.only(bottom: 120),
          ),
        ),
      ],
    );
  }
}

class PlaylistAssetGridView extends StatefulWidget {
  const PlaylistAssetGridView({
    required this.playlist,
    super.key,
    this.header,
    this.backgroundColor = AppColor.auGreyBackground,
    this.padding = EdgeInsets.zero,
  });

  final DP1Call playlist;
  final Widget? header;
  final Color backgroundColor;
  final EdgeInsets padding;

  @override
  State<PlaylistAssetGridView> createState() => _PlaylistAssetGridViewState();
}

class _PlaylistAssetGridViewState extends State<PlaylistAssetGridView> {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  late PlaylistDetailsBloc _playlistDetailsBloc;

  @override
  void initState() {
    super.initState();
    _playlistDetailsBloc = PlaylistDetailsBloc(widget.playlist);
    _playlistDetailsBloc.add(GetPlaylistDetailsEvent());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PlaylistAssetGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist != widget.playlist)
      _playlistDetailsBloc.add(GetPlaylistDetailsEvent());
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
      final state = _playlistDetailsBloc.state;
      if (state.hasMore && state is! PlaylistDetailsLoadingMoreState) {
        _isLoadingMore = true;
        _playlistDetailsBloc.add(LoadMorePlaylistDetailsEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: widget.padding.copyWith(top: 0, bottom: 0),
      // top and bottom will be added by the custom scroll view
      child: BlocConsumer<PlaylistDetailsBloc, PlaylistDetailsState>(
        bloc: _playlistDetailsBloc,
        listener: (context, state) {
          if (state is! PlaylistDetailsLoadingMoreState) {
            _isLoadingMore = false;
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: SizedBox(
                height: widget.padding.top,
              )),
              if (widget.header != null) ...[
                SliverToBoxAdapter(
                  child: widget.header!,
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: UIConstants.detailPageHeaderPadding,
                  ),
                ),
              ],
              if (state is PlaylistDetailsInitialState ||
                  state is PlaylistDetailsLoadingState)
                SliverToBoxAdapter(
                  child: _loadingView(context),
                )
              else if (state.assetTokens.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyView(context),
                )
              else
                UIHelper.assetTokenSliverGrid(
                    context, state.assetTokens, widget.playlist.title),
              if (state is PlaylistDetailsLoadingMoreState)
                const SliverToBoxAdapter(
                    child: LoadMoreIndicator(
                  isLoadingMore: true,
                )),
              SliverToBoxAdapter(
                  child: SizedBox(height: widget.padding.bottom)),
            ],
          );
        },
      ),
    );
  }

  Widget _loadingView(BuildContext context) => LoadingWidget(
        backgroundColor: widget.backgroundColor,
        isInfinitySize: false,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.paddingHorizontal,
          vertical: 60,
        ),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.paddingHorizontal,
        vertical: 60,
      ),
      child: Text('Playlist Empty', style: theme.textTheme.ppMori400White14),
    );
  }
}
