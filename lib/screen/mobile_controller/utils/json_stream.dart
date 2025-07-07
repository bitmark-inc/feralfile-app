import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

class JsonStream {
  final Stream<List<int>> _input;

  JsonStream(this._input);

  Stream<Map<String, dynamic>> get stream async* {
    String buffer = '';
    await for (final data in _input) {
      final chunk = utf8.decode(data);
      buffer += chunk;
      final (jsonStrings, remain) = buffer.extractFullJsonChunks();
      buffer = remain;
      for (final jsonString in jsonStrings) {
        try {
          final json = jsonDecode(jsonString);
          if (json is Map<String, dynamic>) {
            log.info('[JSON STREAM]Decoded JSON: $json');
            yield json;
          } else {
            // Nếu không phải map thì bỏ qua
          }
        } catch (e) {
          log.info('[JSON STREAM]Error decoding JSON: $e');
          // Bỏ qua lỗi decode, có thể là do dữ liệu không hoàn chỉnh
        }
      }
    }
    if (buffer.isNotEmpty && buffer.trim().isNotEmpty && buffer != '\n') {
      try {
        final json = jsonDecode(buffer);
        if (json is Map<String, dynamic>) {
          log.info('[JSON STREAM]Final JSON: $json');
          yield json;
        }
      } catch (e) {
        log.info('[JSON STREAM]Error decoding final JSON: $e');
      }
    }
  }
}
