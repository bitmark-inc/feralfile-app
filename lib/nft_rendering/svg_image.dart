import 'package:autonomy_flutter/nft_rendering/feralfile_webview.dart';
import 'package:flutter/material.dart';

class SvgImage extends StatefulWidget {
  final String url;
  final bool fallbackToWebView;
  final WidgetBuilder? loadingWidgetBuilder;
  final WidgetBuilder? errorWidgetBuilder;
  final WidgetBuilder? unsupportWidgetBuilder;
  final VoidCallback? onLoaded;
  final VoidCallback? onError;
  final Color? backgroundColor;

  const SvgImage({
    required this.url,
    super.key,
    this.fallbackToWebView = false,
    this.loadingWidgetBuilder,
    this.errorWidgetBuilder,
    this.onLoaded,
    this.onError,
    this.unsupportWidgetBuilder,
    this.backgroundColor,
  });

  String getHtml(String svgImageURL) => '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
          }
          img{
            width: 100%;
            height: 100%;
            object-fit: contain;
          }
        </style>
      </head>
      <body>
        <div></div>
        <img src="$svgImageURL" />
      </body>
    </html>
    ''';

  @override
  State<StatefulWidget> createState() => _SvgImageState();
}

class _SvgImageState extends State<SvgImage> {
  bool _webviewLoadFailed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_webviewLoadFailed) {
      return widget.unsupportWidgetBuilder?.call(context) ?? const SizedBox();
    }
    return FeralFileWebview(
      key: Key(widget.url),
      uri: Uri.dataFromString(widget.getHtml(widget.url)),
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      onLoaded: (controller) {
        widget.onLoaded?.call();
      },
      onResourceError: (controller, error) {
        setState(() {
          _webviewLoadFailed = true;
        });
      },
      onHttpError: (controller, error) {
        setState(() {
          _webviewLoadFailed = true;
        });
      },
    );
  }
}

class SvgNotSupported {
  final String svgData;

  SvgNotSupported(this.svgData);
}
