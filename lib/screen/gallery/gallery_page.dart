import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListenerToLoadMore);

    final address = widget.payload.address;

    context.read<GalleryBloc>().add(GetTokensEvent(address));
    context.read<GalleryBloc>().add(ReindexIndexerEvent(address));
  }

  _scrollListenerToLoadMore() {
    if (_scrollController.position.pixels + 100 >=
        _scrollController.position.maxScrollExtent) {
      context.read<GalleryBloc>().add(GetTokensEvent(widget.payload.address));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryBloc>().state;

    return PrimaryScrollController(
      controller: _scrollController,
      child: Scaffold(
        body: Stack(
          fit: StackFit.loose,
          children: [
            _assetsWidget(state.tokens, state.isLoading),
            PenroseTopBarView(
                _scrollController, PenroseTopBarViewStyle.back, null),
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
          alignment: Alignment.topLeft,
          padding: EdgeInsets.fromLTRB(2, 0, 24, 14),
          child: TextButton(
            style: ButtonStyle(alignment: Alignment.centerRight),
            onPressed: artistURL != null ? () => launch(artistURL) : null,
            child: Text(
              widget.payload.artistName,
              style: artistURL != null
                  ? makeLinkStyle(appTextTheme.headline1!)
                  : appTextTheme.headline1,
            ),
          ),
        ),
      ),
      if (tokens == null)
        ...[]
      else if (tokens.isEmpty) ...[
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 0, 24, 14),
            child: Text(
              "Collection is empty for now. Indexing...",
              style: appTextTheme.bodyText1,
            ),
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

    sources.insert(
      0,
      SliverToBoxAdapter(
        child: Container(
          height: 168.0,
        ),
      ),
    );

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
