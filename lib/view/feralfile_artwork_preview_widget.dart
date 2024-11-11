import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/nft_rendering/audio_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/gif_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/image_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/pdf_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/svg_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/video_player_widget.dart';
import 'package:autonomy_flutter/nft_rendering/webview_rendering_widget.dart';
import 'package:autonomy_flutter/screen/account/test_artwork_screen.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeralFileArtworkPreviewWidgetPayload {
  final Artwork artwork;
  final Function({WebViewController? webViewController, int? time})? onLoaded;
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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = testArtworkMode
        ? testArtworkPreviewURL!
        : widget.payload.artwork.previewURL;
    final thumbnailUrl = widget.payload.artwork.thumbnailURL;
    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(
        builder: (context, attempt) =>
            BlocBuilder<FFArtworkPreviewBloc, FFArtworkPreviewState>(
          bloc: context.read<FFArtworkPreviewBloc>(),
          builder: (context, state) {
            final medium = state.mediumMap[previewUrl];
            if (medium == null) {
              return const SizedBox();
            }
            switch (medium) {
              case RenderingType.image:
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: ImageNFTRenderingWidget(
                      previewURL: previewUrl,
                    ),
                  ),
                );
              case RenderingType.video:
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: VideoNFTRenderingWidget(
                      key: Key('video_nft_rendering_widget_$previewUrl'),
                      previewURL: previewUrl,
                      thumbnailURL: thumbnailUrl,
                      isMute: widget.payload.isMute,
                    ),
                  ),
                );
              case RenderingType.gif:
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: GifNFTRenderingWidget(
                      previewURL: previewUrl,
                    ),
                  ),
                );
              case RenderingType.svg:
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                      child: SVGNFTRenderingWidget(previewURL: previewUrl)),
                );
              case RenderingType.pdf:
                return Center(
                  child: PDFNFTRenderingWidget(
                    previewURL: previewUrl,
                  ),
                );
              case RenderingType.audio:
                return Center(
                  child: AudioNFTRenderingWidget(
                    previewURL: previewUrl,
                    thumbnailURL: thumbnailUrl,
                    isMute: widget.payload.isMute,
                  ),
                );
              default:
                return Center(
                  child: WebviewNFTRenderingWidget(
                    previewURL: previewUrl,
                    isMute: widget.payload.isMute,
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
