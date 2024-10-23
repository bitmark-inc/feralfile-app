//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/nft_rendering/gif_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/image_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/pdf_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/svg_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/video_player_widget.dart';
import 'package:autonomy_flutter/nft_rendering/webview_rendering_widget.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArtworkPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final Function({WebViewController? webViewController, int? time})? onLoaded;
  final Function({int? time})? onDispose;
  final bool isMute;
  final FocusNode? focusNode;
  final bool useIndexer;

  const ArtworkPreviewWidget({
    required this.identity,
    super.key,
    this.onLoaded,
    this.onDispose,
    this.isMute = false,
    this.focusNode,
    this.useIndexer = false,
  });

  @override
  State<ArtworkPreviewWidget> createState() => ArtworkPreviewWidgetState();
}

class ArtworkPreviewWidgetState extends State<ArtworkPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  final bloc =
      ArtworkPreviewDetailBloc(injector(), injector(), injector(), injector());
  GlobalKey<NFTRenderingWidgetState>? _artworkKey;
  Widget? _currentRenderingWidget;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _artworkKey = GlobalKey<NFTRenderingWidgetState>(
        debugLabel: 'artwork_preview_key_${widget.identity}');
    bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity,
        useIndexer: widget.useIndexer));
  }

  @override
  void didUpdateWidget(covariant ArtworkPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      _artworkKey = GlobalKey<NFTRenderingWidgetState>(
          debugLabel: 'artwork_preview_key_${widget.identity}');
      bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity,
          useIndexer: widget.useIndexer));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  void pause() {
    _artworkKey?.currentState?.pause();
  }

  void resume() {
    _artworkKey?.currentState?.resume();
  }

  void mute() {
    _artworkKey?.currentState?.mute();
  }

  void unmute() {
    _artworkKey?.currentState?.unmute();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ArtworkPreviewDetailBloc, ArtworkPreviewDetailState>(
        bloc: bloc,
        builder: (context, state) {
          switch (state.runtimeType) {
            case ArtworkPreviewDetailLoadingState:
              return previewPlaceholder();
            case ArtworkPreviewDetailLoadedState:
              final assetToken =
                  (state as ArtworkPreviewDetailLoadedState).assetToken;
              if (assetToken != null) {
                return BlocProvider(
                  create: (_) => RetryCubit(),
                  child: BlocBuilder<RetryCubit, int>(
                    builder: (context, attempt) {
                      if (assetToken.isPostcard) {
                        return Container(
                            alignment: Alignment.center,
                            child: PostcardRatio(assetToken: assetToken));
                      }
                      final previewURL = assetToken.getPreviewUrl() ?? '';

                      switch (assetToken.getMimeType) {
                        case RenderingType.image:
                          _currentRenderingWidget = ImageNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _currentRenderingWidget,
                            ),
                          );
                        case RenderingType.video:
                          _currentRenderingWidget = VideoNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _currentRenderingWidget,
                            ),
                          );
                        case RenderingType.gif:
                          _currentRenderingWidget = GifNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _currentRenderingWidget,
                            ),
                          );
                        case RenderingType.svg:
                          _currentRenderingWidget = SVGNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _currentRenderingWidget,
                            ),
                          );
                        case RenderingType.pdf:
                          _currentRenderingWidget = PDFNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return Center(
                            child: _currentRenderingWidget,
                          );
                        default:
                          _currentRenderingWidget = WebviewNFTRenderingWidget(
                            key: _artworkKey,
                            previewURL: previewURL,
                          );
                          return Center(
                            child: _currentRenderingWidget,
                          );
                      }
                    },
                  ),
                );
              }

              return const SizedBox();
            default:
              return Container();
          }
        },
      );
}

class PostcardPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final bool useIndexer;

  const PostcardPreviewWidget({
    required this.identity,
    super.key,
    this.useIndexer = false,
  });

  @override
  State<PostcardPreviewWidget> createState() => _PostcardPreviewWidgetState();
}

class _PostcardPreviewWidgetState extends State<PostcardPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  final bloc = PostcardDetailBloc(injector(), injector(), injector(),
      injector(), injector(), injector(), injector(), injector());

  @override
  void initState() {
    bloc.add(PostcardDetailGetInfoEvent(widget.identity,
        useIndexer: widget.useIndexer));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostcardDetailBloc, PostcardDetailState>(
          bloc: bloc,
          builder: (context, state) {
            final assetToken = state.assetToken;
            if (assetToken != null) {
              return BlocProvider(
                create: (_) => RetryCubit(),
                child: BlocBuilder<RetryCubit, int>(
                  builder: (context, attempt) => Container(
                      alignment: Alignment.center,
                      child: PostcardRatio(assetToken: assetToken)),
                ),
              );
            }
            return const SizedBox();
          });
}
