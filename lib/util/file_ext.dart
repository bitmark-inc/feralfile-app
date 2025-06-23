import 'dart:io';
import 'dart:typed_data';

extension FileToBytes on File {
  Future<Uint8List> toBytes() {
    return readAsBytes();
  }
}
