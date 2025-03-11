import 'dart:io';

extension BytesBuilderExtension on BytesBuilder {
  void writeVarint(int value) {
    while (value >= 0x80) {
      addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    addByte(value);
  }
}
