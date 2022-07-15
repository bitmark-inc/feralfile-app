import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
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

    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      context.read<GalleryBloc>().add(GetTokensEvent(widget.payload.address));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    return PrimaryScrollController(
      controller: _scrollController,
      child: Scaffold(
        body: Stack(
          fit: StackFit.loose,
          children: [
            BlocConsumer<GalleryBloc, GalleryState>(listener: (context, state) {
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
            }, builder: (context, state) {
              return _assetsWidget(state.tokens, state.isLoading);
            }),
            PenroseTopBarView(_scrollController, PenroseTopBarViewStyle.back),
          ],
        ),
      ),
    );
  }

  Widget _assetsWidget(List<AssetToken>? tokens, bool isLoading) {
    const int cellPerRow = 3;
    const double cellSpacing = 3.0;
    final artistURL = widget.payload.artistURL;

    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    sources = [
      SliverToBoxAdapter(
          child: Container(
        child: autonomyLogo,
        padding: EdgeInsets.fromLTRB(0, 72, 0, 48),
      )),
      SliverToBoxAdapter(
        child: Container(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.fromLTRB(6, 0, 14, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: ButtonStyle(alignment: Alignment.centerRight),
                onPressed: artistURL != null ? () => launch(artistURL) : null,
                child: Text(
                  widget.payload.artistName,
                  style: artistURL != null
                      ? makeLinkStyle(appTextTheme.headline2!)
                      : appTextTheme.headline2,
                ),
              ),
              if (tokens != null && tokens.isEmpty) ...[
                Text('indexing...',
                    style: appTextTheme.headline2?.copyWith(fontSize: 12)),
              ]
            ],
          ),
        ),
      ),
      if (tokens == null)
        ...[]
      else if (tokens.isEmpty) ...[
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cellPerRow,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
            childAspectRatio: 1.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return placeholder();
            },
            childCount: 15,
          ),
        ),
      ] else ...[
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cellPerRow,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
            childAspectRatio: 1.0,
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
            padding: EdgeInsets.fromLTRB(16, 24, 24, 14),
            child: Center(child: loadingIndicator()),
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
