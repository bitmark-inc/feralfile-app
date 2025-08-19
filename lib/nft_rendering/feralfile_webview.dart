// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:autonomy_flutter/nft_rendering/webview_controller_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FeralFileWebview extends StatefulWidget {
  final Uri uri;
  final String? overriddenHtml;
  final bool isMute;
  final Color backgroundColor;
  final String? userAgent;
  final Function(WebViewController webViewController)? onLoaded;
  final Function(WebViewController webViewController)? onStarted;
  final Function(WebViewController webViewController, WebResourceError error)?
      onResourceError;
  final Function(WebViewController webViewController, HttpResponseError error)?
      onHttpError;
  final Function(WebViewController webViewController,
      JavaScriptConsoleMessage consoleMessage)? onConsoleMessage;

  const FeralFileWebview({
    required this.uri,
    super.key,
    this.overriddenHtml,
    this.isMute = false,
    this.backgroundColor = Colors.transparent,
    this.userAgent,
    this.onLoaded,
    this.onStarted,
    this.onResourceError,
    this.onHttpError,
    this.onConsoleMessage,
  });

  @override
  State<FeralFileWebview> createState() => FeralFileWebviewState();
}

class FeralFileWebviewState extends State<FeralFileWebview> {
  late WebViewController _webViewController;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _webViewController = getWebViewController();
    _webViewController.load(
      widget.uri,
      widget.overriddenHtml,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingWidget(
              backgroundColor: widget.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          AnimatedOpacity(
            opacity: _loadingProgress > 0.0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: WebViewWidget(
              key: Key(widget.uri.toString()),
              controller: _webViewController,
            ),
          ),
          Positioned.fill(
            child: Container(
              child: AnimatedOpacity(
                opacity: _loadingProgress < 1.0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildLoadingWidget(),
              ),
            ),
          )
        ],
      );

  @override
  void dispose() {
    super.dispose();
    // webViewController dispose itself
    // _webViewController.dispose();
  }

  @override
  void didUpdateWidget(covariant FeralFileWebview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        oldWidget.overriddenHtml != widget.overriddenHtml) {
      _webViewController.load(
        widget.uri,
        widget.overriddenHtml,
      );
    }
  }

  WebViewController getWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final webViewController = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) {
        // Handle permission requests here
      },
    );
    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..enableZoom(false)
      ..setUserAgent(widget.userAgent)
      ..setOnConsoleMessage((message) {
        log.info('Console: ${message.message}');
        widget.onConsoleMessage?.call(webViewController, message);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (url) async {
            setState(() {
              _loadingProgress = 0.0;
            });
            unawaited(webViewController.skipPrint());
            widget.onStarted?.call(webViewController);
          },
          onPageFinished: (url) async {
            setState(() {
              _loadingProgress = 1.0;
            });
            widget.onLoaded?.call(webViewController);
            if (widget.isMute) {
              await webViewController.mute();
            }
            final html = await webViewController.runJavaScriptReturningResult(
              'document.documentElement.outerHTML',
            );
            log.info('Page finished loading: $url');
          },
          onWebResourceError: (error) {
            log.info('Error: ${error.description}');
            widget.onResourceError?.call(webViewController, error);
          },
          onHttpError: (error) {
            log.info('HttpError: $error');
            widget.onHttpError?.call(webViewController, error);
          },
        ),
      );
    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      unawaited((webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false));
    }
    return webViewController;
  }
}
