import 'dart:math';

import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class DP1PlaylistDetailsScreenPayload {
  const DP1PlaylistDetailsScreenPayload({
    required this.playlist,
    this.customTitle,
  });

  final DP1Call playlist;
  final String? customTitle;
}

class DP1PlaylistDetailsScreen extends StatefulWidget {
  const DP1PlaylistDetailsScreen({required this.payload, super.key});

  @override
  State<DP1PlaylistDetailsScreen> createState() =>
      _DP1PlaylistDetailsScreenState();

  final DP1PlaylistDetailsScreenPayload payload;
}

class _DP1PlaylistDetailsScreenState extends State<DP1PlaylistDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          detailPageAppBar(context, widget.payload.customTitle ?? 'Playlists'),
      backgroundColor: AppColor.auGreyBackground,
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: UIConstants.detailPageHeaderPadding),
        PlaylistItem(playlist: widget.payload.playlist),
        const SizedBox(height: UIConstants.detailPageHeaderPadding),
        Expanded(
          child: PlaylistItemGridView(
            items: widget.payload.playlist.items,
          ),
        ),
      ],
    );
  }
}

class PlaylistItemGridView extends StatefulWidget {
  const PlaylistItemGridView({
    required this.items,
    this.scrollController,
    super.key,
    this.isScrollable = true,
    this.padding = EdgeInsets.zero,
    this.limit,
    this.header,
  });

  final List<DP1Item>? items;
  final ScrollController? scrollController;
  final bool isScrollable;
  final EdgeInsets padding;
  final int? limit;
  final Widget? header;

  @override
  State<PlaylistItemGridView> createState() => _PlaylistItemGridViewState();
}

class _PlaylistItemGridViewState extends State<PlaylistItemGridView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 150),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('Playlist Empty', style: theme.textTheme.ppMori400White14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistItems = widget.items;
    return CustomScrollView(
      controller: _scrollController,
      shrinkWrap: true,
      physics: widget.isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        if (playlistItems == null) ...[
          SliverToBoxAdapter(
            child: _loadingView(context),
          ),
        ] else if (playlistItems.isEmpty) ...[
          SliverToBoxAdapter(
            child: _emptyView(context),
          ),
        ] else ...[
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 188 / 307,
                mainAxisSpacing: 0,
                crossAxisSpacing: 17),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = playlistItems[index];
                final border = Border(
                  top: const BorderSide(
                    color: AppColor.auGreyBackground,
                  ),
                  right: BorderSide(
                    color:
                        // if index is even, show border on the right
                        index.isEven
                            ? AppColor.auGreyBackground
                            : Colors.transparent,
                  ),
                  // if last row, add border on the bottom
                  bottom: index >= playlistItems.length - 2
                      ? const BorderSide(
                          color: AppColor.auGreyBackground,
                        )
                      : BorderSide.none,
                );
                return _item(context, item, border);
              },
              childCount: widget.limit == null
                  ? playlistItems.length
                  : min(widget.limit!, playlistItems.length),
            ),
          ),
        ],
        SliverPadding(
          padding: widget.padding,
          sliver: const SliverToBoxAdapter(),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, DP1Item item, Border border) {
    final title = item.title;
    final artist = item.title;
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              color: Colors.amber,
              height: 500,
              width: 200,
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
          )
        ],
      ),
    );
  }
}
