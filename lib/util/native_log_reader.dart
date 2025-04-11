import 'package:flutter/services.dart';

class NativeLogReader {
  static const platform = MethodChannel('com.feralfile.wallet/log');

  static Future<String> getLogContent() async {
    try {
      final result = await platform.invokeMethod('getLogContent');
      return result as String;
    } on PlatformException catch (e) {
      return 'Failed to get log content: ${e.message}';
    }
  }
}
