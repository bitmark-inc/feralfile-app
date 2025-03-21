import 'package:autonomy_flutter/model/canvas_device_info.dart';

class FailedToConnectToWifiException implements Exception {
  FailedToConnectToWifiException(this.ssid, this.device);

  final String ssid;
  final BaseDevice device;

  @override
  String toString() {
    return 'Failed to connect to wifi: $ssid, $device';
  }
}
