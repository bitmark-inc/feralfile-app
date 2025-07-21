import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

extension WebViewControllerExtension on WebViewController {
  Future<void> evaluateJavascript({required String source}) async {
    try {
      await runJavaScript(source);
    } catch (e) {
      if (kDebugMode) {
        print('Error evaluateJavascript: $e');
      }
    }
  }

  Future<void> mute() async {
    await evaluateJavascript(
        source: "var video = document.getElementsByTagName('video')[0]; "
            'if(video != undefined) { video.muted = true; } '
            "var audio = document.getElementsByTagName('audio')[0]; "
            'if(audio != undefined) { audio.muted = true; }');
  }

  Future<void> skipPrint() async {
    await evaluateJavascript(
      source: "window.print = function () { console.log('Skip printing'); };",
    );
  }

  void onDispose() {
    log.info('WebViewController onDispose');
  }

  void load(Uri uri, String? overriddenHtml) {
    if (overriddenHtml != null) {
      loadHtmlString(
        overriddenHtml,
      );
    } else {
      loadRequest(uri);
    }
  }
}
