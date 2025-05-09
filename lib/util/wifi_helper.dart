import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';

class WifiHelper {
  static Future<void> scanWifiNetwork({
    required FFBluetoothDevice device,
    required Duration timeout,
    required FutureOr<void> Function(List<String> result) onResultScan,
    FutureOr<bool> Function(List<String> result)? shouldStop,
  }) async {
    final startTime = DateTime.now();
    final delay = Duration(seconds: 2);
    while (DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(delay);
      try {
        final result = await injector<FFBluetoothService>().scanWifi(device);
        onResultScan.call(result);
        final shouldStopScan = await shouldStop?.call(result) ?? false;
        if (shouldStopScan) {
          break;
        }
        break;
      } catch (e) {
        print('Error scanning Wi-Fi: $e');
      }
    }
  }
}
