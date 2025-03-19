import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FailedToConnectToWifiException implements Exception {
  final String ssid;
  final BluetoothDevice device;

  FailedToConnectToWifiException(this.ssid, this.device);
}
