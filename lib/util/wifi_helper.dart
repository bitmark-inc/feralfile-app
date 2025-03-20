import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';

class WifiHelper {
  static Future<void> scanWifiNetwork({
    required BaseDevice device,
    required Duration timeout,
    required FutureOr<void> Function(Map<String, bool> result) onResultScan,
    FutureOr<bool> Function(Map<String, bool> result)? shouldStop,
  }) async {
    final startTime = DateTime.now();
    final delay = Duration(seconds: 2);
    while (DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(delay);
      try {
        final result = await injector<CanvasClientServiceV2>().scanWifi(device);
        onResultScan.call(result);
        final shouldStopScan = await shouldStop?.call(result) ?? false;
        if (shouldStopScan) {
          break;
        }
      } catch (e) {
        print('Error scanning Wi-Fi: $e');
      }
    }
  }
}
