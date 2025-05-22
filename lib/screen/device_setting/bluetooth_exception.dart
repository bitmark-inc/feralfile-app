import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FailedToConnectToWifiException implements Exception {
  FailedToConnectToWifiException(this.ssid, this.device);

  final String ssid;
  final BluetoothDevice device;

  @override
  String toString() {
    return 'Failed to connect to wifi: $ssid, $device';
  }
}
