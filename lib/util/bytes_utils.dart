import 'dart:typed_data';

extension BytesUtils on Uint8List {
  String toHexString() => map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();
}
