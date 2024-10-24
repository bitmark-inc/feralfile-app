// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';

/// Get nft rendering widget by type
/// You can add and define more types by creating classes extends
/// [INFTRenderingWidget]
///
const keysCode = {
  'backspace': 8,
  'tab': 9,
  'enter': 13,
  'shift': 16,
  'ctrl': 17,
  'alt': 18,
  'pausebreak': 19,
  'capslock': 20,
  'esc': 27,
  'space': 32,
  'pageup': 33,
  'pagedown': 34,
  'end': 35,
  'home': 36,
  'leftarrow': 37,
  'uparrow': 38,
  'rightarrow': 39,
  'downarrow': 40,
  'insert': 45,
  'delete': 46,
  '0': 48,
  '1': 49,
  '2': 50,
  '3': 51,
  '4': 52,
  '5': 53,
  '6': 54,
  '7': 55,
  '8': 56,
  '9': 57,
  'a': 65,
  'b': 66,
  'c': 67,
  'd': 68,
  'e': 69,
  'f': 70,
  'g': 71,
  'h': 72,
  'i': 73,
  'j': 74,
  'k': 75,
  'l': 76,
  'm': 77,
  'n': 78,
  'o': 79,
  'p': 80,
  'q': 81,
  'r': 82,
  's': 83,
  't': 84,
  'u': 85,
  'v': 86,
  'w': 87,
  'x': 88,
  'y': 89,
  'z': 90,
  'leftwindowkey': 91,
  'rightwindowkey': 92,
  'selectkey': 93,
  'numpad0': 96,
  'numpad1': 97,
  'numpad2': 98,
  'numpad3': 99,
  'numpad4': 100,
  'numpad5': 101,
  'numpad6': 102,
  'numpad7': 103,
  'numpad8': 104,
  'numpad9': 105,
  'multiply': 106,
  'add': 107,
  'subtract': 109,
  'decimalpoint': 110,
  'divide': 111,
  'f1': 112,
  'f2': 113,
  'f3': 114,
  'f4': 115,
  'f5': 116,
  'f6': 117,
  'f7': 118,
  'f8': 119,
  'f9': 120,
  'f10': 121,
  'f11': 122,
  'f12': 123,
  'numlock': 144,
  'scrolllock': 145,
  'semicolon': 186,
  'equalsign': 187,
  'comma': 188,
  'dash': 189,
  'period': 190,
  'forwardslash': 191,
  'graveaccent': 192,
  'openbracket': 219,
  'backslash': 220,
  'closebracket': 221,
  'singlequote': 222
};

class RenderingType {
  static const image = 'image';
  static const svg = 'svg';
  static const gif = 'gif';
  static const audio = 'audio';
  static const video = 'video';
  static const pdf = 'application/pdf';
  static const webview = 'webview';
  static const modelViewer = 'modelViewer';
}

abstract class NFTRenderingWidget extends StatefulWidget {
  const NFTRenderingWidget({super.key});
}

abstract class NFTRenderingWidgetState<T extends NFTRenderingWidget>
    extends State<T> {
  void pause() {}

  void resume() {}

  void mute() {}

  void unmute() {}
}

class NoPreviewUrlWidget extends StatelessWidget {
  const NoPreviewUrlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Center(
          child: ClipPath(
            clipper: RectangleClipper(),
            child: Container(
              padding: const EdgeInsets.all(15),
              height: size.width,
              width: size.width,
              color: Colors.white,
            ),
          ),
        ),
        Center(
          child: ClipPath(
            clipper: RectangleClipper(),
            child: Container(
              padding: const EdgeInsets.all(15),
              height: size.width - 2,
              width: size.width - 2,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class RectangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 14;

    Path path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width - radius, 0)
      ..lineTo(size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
