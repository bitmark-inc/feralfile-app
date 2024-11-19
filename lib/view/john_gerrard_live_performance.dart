import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/nft_rendering/audio_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/gif_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/image_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/pdf_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/svg_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/video_player_widget.dart';
import 'package:autonomy_flutter/nft_rendering/webview_rendering_widget.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JohnGerrardLivePerformanceWidget extends StatefulWidget {
  final Exhibition exhibition;

  const JohnGerrardLivePerformanceWidget({required this.exhibition, super.key});

  @override
  State<JohnGerrardLivePerformanceWidget> createState() =>
      _JohnGerrardLivePerformanceWidgetState();
}

class _JohnGerrardLivePerformanceWidgetState
    extends State<JohnGerrardLivePerformanceWidget>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.exhibition.series!.first.galleryURL;
    final thumbnailUrl = widget.exhibition.series!.first.thumbnailUrl;
    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(
        builder: (context, attempt) {
          final medium = widget.exhibition.series!.first.medium;
          Widget renderingWidget;
          switch (medium) {
            case RenderingType.image:
              renderingWidget = InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: ImageNFTRenderingWidget(
                    previewURL: previewUrl,
                  ),
                ),
              );
            case RenderingType.video:
              renderingWidget = InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: VideoNFTRenderingWidget(
                    previewURL: previewUrl,
                    thumbnailURL: thumbnailUrl,
                  ),
                ),
              );
            case RenderingType.gif:
              renderingWidget = InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: GifNFTRenderingWidget(
                    previewURL: previewUrl,
                  ),
                ),
              );
            case RenderingType.svg:
              renderingWidget = InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                    child: SVGNFTRenderingWidget(previewURL: previewUrl)),
              );
            case RenderingType.pdf:
              renderingWidget = Center(
                child: PDFNFTRenderingWidget(
                  previewURL: previewUrl,
                ),
              );
            case RenderingType.audio:
              renderingWidget = Center(
                child: AudioNFTRenderingWidget(
                  previewURL: previewUrl,
                ),
              );
            default:
              renderingWidget = Center(
                child: WebviewNFTRenderingWidget(
                  previewURL: previewUrl,
                ),
              );
          }
          return Center(
            child: renderingWidget,
          );
        },
      ),
    );
  }
}
