import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  // For scanning
  static String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

// command characteristic
  static String commandCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

// wifi connect characteristic
  static String wifiConnectCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

// characteristic for sending commands to Peripheral
  static final _commandCharacteristic = <String, BluetoothCharacteristic>{};

// characteristic to send Wi-Fi credentials to Peripheral
  static final _wifiConnectCharacteristic = <String, BluetoothCharacteristic>{};

  static void setCommandCharacteristic(BluetoothCharacteristic characteristic) {
    _commandCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  static void setWifiConnectCharacteristic(
      BluetoothCharacteristic characteristic) {
    _wifiConnectCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  static BluetoothCharacteristic? getCommandCharacteristic(String remoteId) =>
      _commandCharacteristic[remoteId];

  static BluetoothCharacteristic? getWifiConnectCharacteristic(
          String remoteId) =>
      _wifiConnectCharacteristic[remoteId];
}
