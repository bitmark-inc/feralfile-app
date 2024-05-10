import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:network_info_plus/network_info_plus.dart';

class LocalNetworkHelper {
  static Future<bool> requestLocalNetworkPermission() async {
    bool isGranted = false;
    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      log.info('[LocalNetworkHelper] wifiIp: $wifiIp');
      await Socket.connect(wifiIp, 80,
          timeout: const Duration(milliseconds: 100));
      isGranted = true;
    } catch (e) {
      log.info('[LocalNetworkHelper] requestLocalNetworkPermission Error: $e');
      isGranted = false;
    }
    return isGranted;
  }
}
