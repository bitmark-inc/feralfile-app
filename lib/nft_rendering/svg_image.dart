import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/nft_rendering/feralfile_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';
import 'package:xml/xml.dart';

class SvgImage extends StatefulWidget {
  final String url;
  final bool fallbackToWebView;
  final WidgetBuilder? loadingWidgetBuilder;
  final WidgetBuilder? errorWidgetBuilder;
  final WidgetBuilder? unsupportWidgetBuilder;
  final VoidCallback? onLoaded;
  final VoidCallback? onError;

  const SvgImage({
    required this.url,
    super.key,
    this.fallbackToWebView = false,
    this.loadingWidgetBuilder,
    this.errorWidgetBuilder,
    this.onLoaded,
    this.onError,
    this.unsupportWidgetBuilder,
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
  final Completer<String> _svgString = Completer();
  bool _webviewLoadFailed = false;

  @override
  void initState() {
    Future(() async {
      String? svg;
      try {
        final resp = await http.get(Uri.parse(widget.url));
        svg = resp.body;

        if (widget.fallbackToWebView) {
          svg = await _fixSvgSize(
            svgData: svg,
          );
        }
        parse(svg);
        _svgString.complete(svg);
      } catch (e) {
        if (svg != null) {
          _svgString.completeError(SvgNotSupported(svg));
        } else {
          _svgString.completeError(e);
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _svgString.future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SvgPicture.string(snapshot.data ?? '');
          } else if (snapshot.error is SvgNotSupported &&
              widget.fallbackToWebView &&
              !_webviewLoadFailed &&
              !Platform.isMacOS) {
            return FeralFileWebview(
              key: Key(widget.url),
              uri: Uri.dataFromString(widget.getHtml(widget.url)),
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
          if (snapshot.error is SvgNotSupported && !widget.fallbackToWebView) {
            return widget.unsupportWidgetBuilder?.call(context) ??
                const SizedBox();
          }
          if (snapshot.hasError || _webviewLoadFailed) {
            return widget.errorWidgetBuilder?.call(context) ?? const SizedBox();
          }
          return widget.loadingWidgetBuilder?.call(context) ?? const SizedBox();
        },
      );
}

class SvgNotSupported {
  final String svgData;

  SvgNotSupported(this.svgData);
}

Future<String> _fixSvgSize({
  required String svgData,
}) async =>
    compute<String, String>((svg) {
      final doc = XmlDocument.parse(svg);
      final root = doc.findElements('svg').first;
      root.setAttribute('width', '100%');
      root.setAttribute('height', '100%');
      return doc.toXmlString();
    }, svgData);
