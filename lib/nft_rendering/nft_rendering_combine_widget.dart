import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/material.dart';

// The widget can be called for nft rendering
class NFTRenderingCombineWidget extends StatefulWidget {
  final String mimeType;
  final String previewURL;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const NFTRenderingCombineWidget({
    required this.mimeType,
    required this.previewURL,
    super.key,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  State<StatefulWidget> createState() => _NFTRenderingCombineWidget();
}

class _NFTRenderingCombineWidget extends State<NFTRenderingCombineWidget> {
  late INFTRenderingWidget _renderingWidget;

  @override
  Widget build(BuildContext context) => _buildRenderingWidget(context);

  Widget _buildRenderingWidget(BuildContext context) {
    // if typesOfNFTRenderingWidget doesn't have mimeType, we will return webview nft rendering
    _renderingWidget = typesOfNFTRenderingWidget(widget.mimeType);

    _renderingWidget.setRenderWidgetBuilder(RenderingWidgetBuilder(
      loadingWidget: widget.loadingWidget,
      errorWidget: widget.errorWidget,
      previewURL: widget.previewURL,
    ));

    return Container(
      child: _renderingWidget.build(context),
    );
  }
}
