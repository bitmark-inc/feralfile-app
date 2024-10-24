import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart'; // Make sure to have the right import for your ModelViewer

class ModelViewerRenderingWidget extends NFTRenderingWidget {
  final String previewURL;
  final Widget noPreviewUrlWidget; // Added parameter for noPreviewUrlWidget

  const ModelViewerRenderingWidget({
    required this.previewURL,
    required this.noPreviewUrlWidget,
    super.key,
  });

  @override
  State<ModelViewerRenderingWidget> createState() =>
      _ModelViewerRenderingWidgetState();
}

class _ModelViewerRenderingWidgetState
    extends State<ModelViewerRenderingWidget> {
  @override
  Widget build(BuildContext context) {
    // Check if the previewURL is empty and show the noPreviewUrlWidget if it is
    if (widget.previewURL.isEmpty) {
      return widget.noPreviewUrlWidget; // Show no preview URL widget
    }

    return _widgetBuilder();
  }

  Widget _widgetBuilder() => Stack(
        children: [
          ModelViewer(
            key: Key(widget.previewURL),
            src: widget.previewURL,
            ar: true,
            autoRotate: true,
          ),
        ],
      );
}
