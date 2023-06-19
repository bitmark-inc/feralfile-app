import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gif_view/gif_view.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/models.dart';

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
    log.info("[Postcard] add stamp ${widget.imagePath}, ${widget.jsonPath}");
    if (widget.imagePath == null || widget.jsonPath == null) return;
    final image = await File(widget.imagePath!).readAsBytes();
    final json = await File(widget.jsonPath!).readAsBytes();
    base64Json = base64Encode(json);
    //base64Json = 'eyJhZGRyZXNzIjogImNvbW1pbmciLCAic3RhbXBlZEF0IjogIjIwMjMtMDItMTJUMTk6MjU6MTRaIn0=';
    base64Image = base64Encode(image);
    // base64Image =
    //base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAVkAAAFYCAYAAAD5ro9+AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAVVSURBVHgB7di9kY5hGIbhe3kxEptIVwNUoAJCEkJF6IA+tCGUEEkMTcgw42d3vx+yrwHnzPvtHEfwFPAE59xzncyzt28GgMKn5d/zYgD4/07m3bUBICOyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChJYBjtqDzW5Od/vh4PONa/Pj5GTWQGThyL36dj4Pz7fDwdO7t+f9reuzBuYCgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgNAycERefz+fR382w8HpblgxkeWo3NnPnG32A8fCXAAQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCy7Baj39v5sFmNxzcv9gOHBORXbHH59t59vNygONlLgAIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgChZVbibLufe9vdcHC28R9w7FYT2ee/Luflj4sBuErMBQAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgAhkQUIiSxASGQBQiILEBJZgJDIAoREFiAksgCh5ePXn7MGp7sBuHKWs81+AGiYCwBCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWILQ8uXt7AK6SLzfXcz8uH25dHwAa5gKAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWICSyACGRBQiJLEBIZAFCIgsQElmAkMgChEQWIPQX2B45BdAPrLcAAAAASUVORK5CYII=';
    if (base64Image != null && base64Json != null) {
      log.info("[Postcard] getNewStamp");
      log.info(base64Json);
      log.info(base64Image);
      _controller?.evaluateJavascript(
        source: "getNewStamp('$base64Image', '$base64Json')",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = injector<ConfigurationService>().getVersionInfo();
    return Stack(
      alignment: Alignment.center,
      children: [
        InAppWebView(
          initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  userAgent: "user_agent"
                      .tr(namedArgs: {"version": version.toString()}))),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onConsoleMessage: (InAppWebViewController controller,
              ConsoleMessage consoleMessage) {
            log.info(
                "[Postcard] Software artwork console log: ${consoleMessage.message}");
            if (consoleMessage.message == POSTCARD_SOFTWARE_FULL_LOAD_MESSAGE) {
              _convertFileToBase64().then((value) {
                setState(() {
                  isLoading = false;
                });
              });
            }
          },
          initialUrlRequest: URLRequest(
            url: Uri.parse(widget.assetToken.getPreviewUrl() ?? ""),
          ),
        ),
        if (isLoading)
          Positioned.fill(
              child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: GifView.asset(
                "assets/images/loading_white_tran.gif",
                width: 52,
                height: 52,
                frameRate: 12,
              ),
            ),
          )),
      ],
    );
  }
}

class PostcardRatio extends StatelessWidget {
  final AssetToken assetToken;
  final String? imagePath;
  final String? jsonPath;

  const PostcardRatio(
      {super.key, required this.assetToken, this.imagePath, this.jsonPath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: postcardAspectRatio,
      child: PostcardViewWidget(
        assetToken: assetToken,
        imagePath: imagePath,
        jsonPath: jsonPath,
      ),
    );
  }
}
