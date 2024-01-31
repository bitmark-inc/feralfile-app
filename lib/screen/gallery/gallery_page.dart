import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/models/asset_token.dart';

class GalleryPagePayload {
  String address;
  String artistName;
  String? artistURL;

  GalleryPagePayload({
    required this.address,
    required this.artistName,
    this.artistURL,
  });
}

class GalleryPage extends StatefulWidget {
  final GalleryPagePayload payload;

  const GalleryPage({required this.payload, super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late ScrollController _scrollController;
  int _cachedImageSize = 0;
  Timer? _timer;
  int? _latestTokensLength;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListenerToLoadMore);

    final address = widget.payload.address;

    context.read<GalleryBloc>().add(GetTokensEvent(address));
    context.read<GalleryBloc>().add(ReindexIndexerEvent(address));

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      context.read<GalleryBloc>().add(GetTokensEvent(widget.payload.address));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListenerToLoadMore() {
    if (_scrollController.position.pixels + 100 >=
            _scrollController.position.maxScrollExtent &&
        _latestTokensLength != 0 &&
        !_isLastPage) {
      context.read<GalleryBloc>().add(GetTokensEvent(widget.payload.address));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PrimaryScrollController(
      controller: _scrollController,
      child: BlocConsumer<GalleryBloc, GalleryState>(
        listener: (context, state) {
          final tokens = state.tokens;
          if (tokens == null) {
            return;
          }

          _latestTokensLength = tokens.length;
          _isLastPage = state.isLastPage;

          if (tokens.isNotEmpty) {
            _timer?.cancel();
            if (_latestTokensLength == 0) {
              Vibrate.feedback(FeedbackType.light);
            }
          }
        },
        builder: (context, state) {
          final tokens = state.tokens;
          return Scaffold(
            appBar: getBackAppBar(context,
                title: widget.payload.artistName,
                onBack: () => Navigator.pop(context),
                isWhite: false),
            backgroundColor: theme.colorScheme.primary,
            body: _assetsWidget(tokens, state.isLoading),
          );
        },
      ),
    );
  }

  Widget _assetsWidget(List<CompactedAssetToken>? tokens, bool isLoading) {
    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3;
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    sources = [
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 40,
        ),
      ),
      if (tokens == null)
        ...[]
      else if (tokens.isEmpty) ...[
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cellPerRow,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => placeholder(context),
            childCount: 15,
          ),
        ),
      ] else ...[
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cellPerRow,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final token = tokens[index];

              return GestureDetector(
                onTap: () async {
                  if (token.pending == true && !token.hasMetadata) {
                    return;
                  }
                  final payload = ArtworkDetailPayload(
                      [ArtworkIdentity(token.id, token.owner)], 0,
                      useIndexer: true);
                  unawaited(Navigator.of(context).pushNamed(
                      AppRouter.artworkDetailsPage,
                      arguments: payload));

                  unawaited(injector<MetricClientService>().addEvent(
                      MixpanelEvent.viewArtwork,
                      data: {'id': token.id}));
                },
                child: tokenGalleryThumbnailWidget(
                    context, token, _cachedImageSize),
              );
            },
            childCount: tokens.length,
          ),
        ),
      ],
      if (isLoading) ...[
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 24, 14),
            child: Center(
              child: loadingIndicator(
                valueColor: AppColor.white,
                backgroundColor: AppColor.auLightGrey,
              ),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: Container(
          height: 40,
        ),
      )
    ];

    return CustomScrollView(
      slivers: sources,
      controller: _scrollController,
    );
  }
}
