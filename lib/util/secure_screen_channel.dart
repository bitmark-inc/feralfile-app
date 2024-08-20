import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';

class SecureScreenChannel {
  static const MethodChannel _channel = MethodChannel('secure_screen_channel');

  static void setSecureFlag(bool secure) {
    try {
      unawaited(_channel.invokeMethod('setSecureFlag', {'secure': secure}));
    } catch (e) {
      log.info('Error setting secure flag: $e');
    }
  }
}
