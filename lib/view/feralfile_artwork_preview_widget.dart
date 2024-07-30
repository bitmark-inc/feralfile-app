import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_state.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nft_rendering/nft_rendering.dart';

class FeralFileArtworkPreviewWidgetPayload {
  final Artwork artwork;
  final Function({InAppWebViewController? webViewController, int? time})?
      onLoaded;
  final bool isMute;
  final bool isScrollable;

  FeralFileArtworkPreviewWidgetPayload({
    required this.artwork,
    required this.isMute,
    this.onLoaded,
    this.isScrollable = false,
  });
}

class FeralfileArtworkPreviewWidget extends StatefulWidget {
  final FeralFileArtworkPreviewWidgetPayload payload;

  const FeralfileArtworkPreviewWidget({required this.payload, super.key});

  @override
  State<FeralfileArtworkPreviewWidget> createState() =>
      _FeralfileArtworkPreviewWidgetState();
}

class _FeralfileArtworkPreviewWidgetState
    extends State<FeralfileArtworkPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    context.read<FFArtworkPreviewBloc>().add(
          FFArtworkPreviewConfigByArtwork(widget.payload.artwork),
        );
    super.initState();
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
    _renderingWidget?.didPopNext();
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

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.payload.artwork.previewURL;
    final thumbnailUrl = widget.payload.artwork.thumbnailURL;
    final artwork = widget.payload.artwork;
    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(
        builder: (context, attempt) {
          if (attempt > 0) {
            _renderingWidget?.dispose();
            _renderingWidget = null;
          }
          return BlocBuilder<FFArtworkPreviewBloc, FFArtworkPreviewState>(
            bloc: context.read<FFArtworkPreviewBloc>(),
            builder: (context, state) {
              final medium = state.medium;
              if (medium == null) {
                return const SizedBox();
              }
              _renderingWidget ??= buildFeralfileRenderingWidget(
                context,
                attempt: attempt > 0 ? attempt : null,
                isMute: widget.payload.isMute,
                mimeType: medium,
                previewURL: previewUrl,
                thumbnailURL: thumbnailUrl,
                isScrollable: widget.payload.isScrollable,
                onLoaded: widget.payload.onLoaded,
              );
              switch (medium) {
                case RenderingType.image:
                case RenderingType.video:
                case RenderingType.gif:
                case RenderingType.svg:
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: _artworkView(context),
                    ),
                  );
                case RenderingType.pdf:
                  return Center(
                    child: _artworkView(context),
                  );
                default:
                  return Center(
                    child: artwork.series?.exhibitionID ==
                            JohnGerrardHelper.exhibitionID
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _artworkView(context),
                              ),
                            ),
                          )
                        : _artworkView(context),
                  );
              }
            },
          );
        },
      ),
    );
  }

  Widget _artworkView(BuildContext context) => GestureDetector(
      onTap: () async {
        await _renderingWidget?.pauseOrResume();
      },
      child: _renderingWidget?.build(context) ?? const SizedBox());
}
