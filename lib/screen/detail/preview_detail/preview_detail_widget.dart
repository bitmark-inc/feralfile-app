//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nft_collection/models/asset_token.dart';

class ArtworkPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final Function({InAppWebViewController? webViewController, int? time})?
      onLoaded;
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

  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity,
        useIndexer: widget.useIndexer));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ArtworkPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity,
          useIndexer: widget.useIndexer));
    }
  }

  @override
  void dispose() {
    _renderingWidget?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    if (!CustomRouteObserver.onIgnoreBackLayerPopUp) {
      _renderingWidget?.didPopNext();
    }
    super.didPopNext();
  }

  @override
  void didPushNext() {
    if (!CustomRouteObserver.onIgnoreBackLayerPopUp) {
      unawaited(_renderingWidget?.clearPrevious());
    }
    super.didPushNext();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  void _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      // ignore: cast_nullable_to_non_nullable
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  void pause() {
    unawaited(_renderingWidget?.resume());
  }

  void resume() {
    unawaited(_renderingWidget?.resume());
  }

  void mute() {
    unawaited(_renderingWidget?.mute());
  }

  void unmute() {
    unawaited(_renderingWidget?.unmute());
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
                      if (attempt > 0) {
                        _renderingWidget?.dispose();
                        _renderingWidget = null;
                      }
                      if (_renderingWidget == null ||
                          _renderingWidget!.previewURL !=
                              assetToken.getPreviewUrl()) {
                        _renderingWidget = buildRenderingWidget(
                          context,
                          assetToken,
                          attempt: attempt > 0 ? attempt : null,
                          onLoaded: widget.onLoaded,
                          onDispose: widget.onDispose,
                          overriddenHtml: state.overriddenHtml,
                          isMute: widget.isMute,
                          focusNode: widget.focusNode,
                        );
                      }

                      switch (assetToken.getMimeType) {
                        case RenderingType.image:
                        case RenderingType.video:
                        case RenderingType.gif:
                        case RenderingType.svg:
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _artworkView(assetToken),
                            ),
                          );
                        case RenderingType.pdf:
                          return Center(
                            child: _artworkView(assetToken),
                          );
                        default:
                          return Center(
                            child: _artworkView(assetToken),
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

  Widget _artworkView(AssetToken assetToken) => GestureDetector(
      onTap: () async {
        await _renderingWidget?.pauseOrResume();
      },
      child: _renderingWidget?.build(context) ?? const SizedBox());
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
