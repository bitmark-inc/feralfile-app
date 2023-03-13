import 'dart:async';

import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const GalleryPage({Key? key, required this.payload}) : super(key: key);

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

  _scrollListenerToLoadMore() {
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
          if (tokens == null) return;

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
          final artistURL = widget.payload.artistURL;
          final tokens = state.tokens;
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 0,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'artist_collection'.tr(),
                    style: theme.textTheme.ppMori400Grey12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: artistURL != null
                            ? () {
                                final uri = Uri.tryParse(artistURL);
                                if (uri != null) {
                                  launchUrl(uri);
                                }
                              }
                            : null,
                        child: Text(
                          widget.payload.artistName,
                          style: theme.textTheme.ppMori400White12,
                        ),
                      ),
                      if (tokens != null && tokens.isEmpty) ...[
                        Text(
                          'indexing'.tr(),
                          style: theme.textTheme.ppMori400White12,
                        ),
                      ]
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    AuIcon.close,
                    color: theme.colorScheme.secondary,
                  ),
                  tooltip: 'close_icon',
                )
              ],
            ),
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
    const double cellSpacing = 3.0;
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
            (BuildContext context, int index) {
              return placeholder(context);
            },
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

              return tokenGalleryThumbnailWidget(
                  context, token, _cachedImageSize);
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
      ]
    ];

    sources.add(
      SliverToBoxAdapter(
        child: Container(
          height: 40.0,
        ),
      ),
    );

    return CustomScrollView(
      slivers: sources,
      controller: _scrollController,
    );
  }
}
