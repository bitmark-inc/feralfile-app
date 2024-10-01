import 'dart:async';

import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/webview_controller_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewControllerTextField extends StatelessWidget {
  final WebViewController? webViewController;
  final FocusNode focusNode;
  final TextEditingController textController;
  final List<String> disableKeys;

  const WebviewControllerTextField(
      {required this.focusNode,
      required this.textController,
      super.key,
      this.disableKeys = const [],
      this.webViewController});

  @override
  Widget build(BuildContext context) => TextFormField(
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        controller: textController,
        focusNode: focusNode,
        onChanged: (value) {
          if (!disableKeys.contains(value.characters.last.toLowerCase())) {
            log.info('Sending key: ${value.characters.last}');
            unawaited(webViewController?.evaluateJavascript(source: """
window.dispatchEvent(new KeyboardEvent('keydown', {'key': '${value.characters.last}','keyCode': ${keysCode[value.characters.last]},'which': ${keysCode[value.characters.last]}}));window.dispatchEvent(new KeyboardEvent('keypress', {'key': '${value.characters.last}','keyCode': ${keysCode[value.characters.last]},'which': ${keysCode[value.characters.last]}}));window.dispatchEvent(new KeyboardEvent('keyup', {'key': '${value.characters.last}','keyCode': ${keysCode[value.characters.last]},'which': ${keysCode[value.characters.last]}}));"""));
          }
          textController.text = '';
        },
      );
}

class WebviewControllerTextFieldPayload {
  final WebViewController? webViewController;
  final FocusNode focusNode;
  final TextEditingController textController;

  WebviewControllerTextFieldPayload({
    required this.webViewController,
    required this.focusNode,
    required this.textController,
  });
}
