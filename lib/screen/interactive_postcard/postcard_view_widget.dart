import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gif_view/gif_view.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/models.dart';

class PostcardViewWidget extends StatefulWidget {
  final AssetToken assetToken;
  final String? imagePath;
  final String? jsonPath;
  final int? zoomIndex;
  final Color backgroundColor;
  final bool withPreviewStamp;

  const PostcardViewWidget({
    required this.assetToken,
    super.key,
    this.imagePath,
    this.jsonPath,
    this.zoomIndex,
    this.backgroundColor = Colors.black,
    this.withPreviewStamp = false,
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

  void _zoomIntoStamp({required int index, Color color = Colors.black}) {
    log.info(
        '[Postcard] zoom into stamp $index, ${color.value.toRadixString(16)}');
    final hexColor = color.value.toRadixString(16).substring(2);
    unawaited(_controller?.evaluateJavascript(
      source: "zoomInStamp('$index', \"#$hexColor\")",
    ));
  }

  void _getNewStamp(String base64Image, String base64Json, int index) {
    log.info('[Postcard] getNewStamp');
    unawaited(_controller?.evaluateJavascript(
      source: "getNewStamp('$base64Image', '$base64Json')",
    ));
    log
      ..info('[Postcard] getNewStamp')
      ..info('[Postcard] $index')
      ..info(base64Json)
      ..info('[Postcard] base64Image ${base64Image.runtimeType}');
    unawaited(_controller?.evaluateJavascript(
      source: "getNewStamp($index, '$base64Image', '$base64Json')",
    ));
  }

  Future<void> _convertFileToBase64() async {
    log.info('[Postcard] add stamp ${widget.imagePath}, ${widget.jsonPath}');
    if (widget.imagePath == null || widget.jsonPath == null) {
      return;
    }
    final image = await File(widget.imagePath!).readAsBytes();
    final json = await File(widget.jsonPath!).readAsBytes();

    base64Json = base64Encode(json);
    base64Image = base64Encode(image);
    final index = widget.assetToken.getArtists.length;
    if (base64Image != null && base64Json != null) {
      _getNewStamp(base64Image!, base64Json!, index);
    }
  }

  Future<void> _addPreviewStamp() async {
    final Map<String, dynamic> metadata = {
      'address': '',
      'claimAddress': '',
      'stampedAt': '',
    };
    final base64Json = base64Encode(utf8.encode(jsonEncode(metadata)));
    final data =
        await PlatformAssetBundle().load('assets/images/pink_stamp.png');
    final image =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final base64Image = base64Encode(image);
    final index = widget.assetToken.getArtists.length;
    _getNewStamp(base64Image, base64Json, index);
  }

  @override
  Widget build(BuildContext context) {
    final version = injector<ConfigurationService>().getVersionInfo();
    return Stack(
      alignment: Alignment.center,
      children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            userAgent: 'user_agent'.tr(namedArgs: {'version': version}),
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onConsoleMessage: (InAppWebViewController controller,
              ConsoleMessage consoleMessage) async {
            log.info('[Postcard] Software artwork console log: '
                '${consoleMessage.message}');
            if (consoleMessage.message == POSTCARD_SOFTWARE_FULL_LOAD_MESSAGE) {
              await _convertFileToBase64();
              if (widget.withPreviewStamp) {
                await _addPreviewStamp();
              }
              if (widget.zoomIndex != null) {
                _zoomIntoStamp(
                    index: widget.zoomIndex!, color: widget.backgroundColor);
              }
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            }
          },
          initialUrlRequest: URLRequest(
            url: WebUri(widget.assetToken.getPreviewUrl() ?? ''),
          ),
        ),
        if (isLoading)
          Positioned.fill(
              child: Container(
            width: double.infinity,
            height: double.infinity,
            color: widget.backgroundColor,
            child: Center(
              child: GifView.asset(
                'assets/images/loading_white_tran.gif',
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
  final double? ratio;

  const PostcardRatio(
      {required this.assetToken,
      super.key,
      this.imagePath,
      this.jsonPath,
      this.ratio});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: ratio ?? postcardAspectRatio,
        child: PostcardViewWidget(
          key: key,
          assetToken: assetToken,
          imagePath: imagePath,
          jsonPath: jsonPath,
        ),
      );
}
