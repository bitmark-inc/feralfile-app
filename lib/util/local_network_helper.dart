import 'package:network_info_plus/network_info_plus.dart';

class LocalNetworkHelper {
  static Future<bool> requestLocalNetworkPermission() async {
    bool isGranted = false;
    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      isGranted = true;
    } catch (e) {
      isGranted = false;
    }
    return isGranted;
  }
}
