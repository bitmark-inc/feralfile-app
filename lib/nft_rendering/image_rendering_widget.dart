import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/material.dart';

class ImageNFTRenderingWidget extends NFTRenderingWidget {
  final String previewURL;
  final VoidCallback? onLoaded;
  final Widget? noPreviewUrlWidget;
  final Widget? errorWidget;
  final ImageLoadingBuilder? loadingBuilder;

  const ImageNFTRenderingWidget({
    required this.previewURL,
    super.key,
    this.onLoaded,
    this.noPreviewUrlWidget,
    this.errorWidget,
    this.loadingBuilder,
  });

  @override
  State<ImageNFTRenderingWidget> createState() =>
      _ImageNFTRenderingWidgetState();
}

class _ImageNFTRenderingWidgetState extends State<ImageNFTRenderingWidget> {
  @override
  void initState() {
    super.initState();
    // Notify when the widget has loaded
    widget.onLoaded?.call();
  }

  Widget _buildImageWidget() {
    // If the preview URL is not provided, show a fallback widget
    if (widget.previewURL.isEmpty) {
      return widget.noPreviewUrlWidget ?? const SizedBox.shrink();
    }

    return Image.network(
      widget.previewURL,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: (context, url, error) => Center(
        child: widget.errorWidget ?? const Icon(Icons.error),
      ),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) => _buildImageWidget();
}
