import 'package:autonomy_flutter/nft_rendering/nft_error_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/material.dart';

class GifNFTRenderingWidget extends NFTRenderingWidget {
  final String previewURL;
  final Widget? noPreviewUrlWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final VoidCallback? onLoaded;

  const GifNFTRenderingWidget({
    required this.previewURL,
    super.key,
    this.noPreviewUrlWidget,
    this.loadingWidget,
    this.errorWidget,
    this.onLoaded,
  });

  @override
  State<GifNFTRenderingWidget> createState() => _GifNFTRenderingWidgetState();
}

class _GifNFTRenderingWidgetState extends State<GifNFTRenderingWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.previewURL.isEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildGifWidget() {
    if (widget.previewURL.isEmpty) {
      return widget.noPreviewUrlWidget ?? const SizedBox.shrink();
    }

    return Image.network(
      widget.previewURL,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _onImageLoaded();
          return child;
        }
        return widget.loadingWidget ?? const LoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) =>
          widget.errorWidget ?? const NFTErrorWidget(),
    );
  }

  void _onImageLoaded() {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
      widget.onLoaded?.call();
    }
  }

  @override
  Widget build(BuildContext context) => _isLoading
      ? widget.loadingWidget ?? const Center(child: CircularProgressIndicator())
      : _buildGifWidget();

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> clearPrevious() => Future.value(true);
}
