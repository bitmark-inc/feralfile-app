import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

class PostcardViewWidget extends StatefulWidget {
  final AssetToken assetToken;
  final String? imagePath;
  final String? jsonPath;
  const PostcardViewWidget({
    super.key,
    required this.assetToken,
    this.imagePath,
    this.jsonPath,
  });

  @override
  State<PostcardViewWidget> createState() => _PostcardViewWidgetState();
}

class _PostcardViewWidgetState extends State<PostcardViewWidget> {
  bool isLoading = true;
  String? base64Image;
  String? base64Json;

  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
  }

  _convertFileToBase64() async {
    if (widget.imagePath == null || widget.jsonPath == null) return;

    final bytes = await rootBundle.load('assets/images/loading_white_tran.gif');
    base64Json =
        'eyJhZGRyZXNzIjogImNvbW1pbmciLCAic3RhbXBlZEF0IjogIjIwMjMtMDItMTJUMTk6MjU6MTRaIn0=';
    base64Image = base64Encode(bytes.buffer.asUint8List());
    // base64Image =
    //     'iVBORw0KGgoAAAANSUhEUgAAAVkAAAFYCAYAAAD5ro9+AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAVVSURBVHgB7di9kY5hGIbhe3kxEptIVwNUoAJCEkJF6IA+tCGUEEkMTcgw42d3vx+yrwHnzPvtHEfwFPAE59xzncyzt28GgMKn5d/zYgD4/07m3bUBICOyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChJYBjtqDzW5Od/vh4PONa/Pj5GTWQGThyL36dj4Pz7fDwdO7t+f9reuzBuYCgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgNAycERefz+fR382w8HpblgxkeWo3NnPnG32A8fCXAAQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCy7Baj39v5sFmNxzcv9gOHBORXbHH59t59vNygONlLgAIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgChZVbibLufe9vdcHC28R9w7FYT2ee/Luflj4sBuErMBQAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgCh5ePXn7MGp7sBuHKWs81+AGiYCwBCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWILQ8uXt7AK6SLzfXcz8uH25dHwAa5gKAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWIPQX2B45BdAPrLcAAAAASUVORK5CYII=';
    if (base64Image != null && base64Json != null) {
      _controller?.evaluateJavascript(
        source: "updateImgSrc('$base64Image', '$base64Json')",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        InAppWebView(
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onLoadStop: (controller, url) {
            setState(() {
              isLoading = false;
            });
            _convertFileToBase64();
          },
          initialUrlRequest: URLRequest(
            url: Uri.parse('http://192.168.31.237:8080/'),
          ),
        ),
        if (isLoading)
          Center(
            child: GifView.asset(
              "assets/images/loading_white_tran.gif",
              width: 52,
              height: 52,
              frameRate: 12,
            ),
          )
      ],
    );
  }
}
