// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:autonomy_flutter/nft_rendering/webview_controller_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FeralFileWebview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final webviewController = WebViewController();
    return WebViewWidget(
      key: Key(uri.toString()),
      controller: webviewController,
    );
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
      ..setBackgroundColor(backgroundColor)
      ..enableZoom(false)
      ..setUserAgent(userAgent)
      ..setOnConsoleMessage((message) {
        log.info('Console: ${message.message}');
        onConsoleMessage?.call(webViewController, message);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            await webViewController.skipPrint();
            onStarted?.call(webViewController);
          },
          onPageFinished: (url) async {
            onLoaded?.call(webViewController);
            if (isMute) {
              await webViewController.mute();
            }
          },
          onWebResourceError: (error) {
            log.info('Error: ${error.description}');
            onResourceError?.call(webViewController, error);
          },
          onHttpError: (error) {
            log.info('HttpError: $error');
            onHttpError?.call(webViewController, error);
          },
        ),
      )
      ..loadRequest(uri);
    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      unawaited((webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false));
    }
    return webViewController;
  }
}
