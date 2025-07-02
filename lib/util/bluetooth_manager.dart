import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  // single ton
  static final BluetoothManager instance = BluetoothManager._internal();

  factory BluetoothManager() => instance;

  BluetoothManager._internal();

  // For scanning
  static String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

// wifi connect characteristic
  static String wifiConnectCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

// characteristic to send Wi-Fi credentials to Peripheral
  final _wifiConnectCharacteristic = <String, BluetoothCharacteristic>{};

  static void setWifiConnectCharacteristic(
      BluetoothCharacteristic characteristic) {
    log.info('Setting Wi-Fi connect characteristic: ${characteristic.uuid}');

    instance._wifiConnectCharacteristic[characteristic.remoteId.str] =
        characteristic;
  }

  BluetoothCharacteristic? getWifiConnectCharacteristic(String remoteId) =>
      _wifiConnectCharacteristic[remoteId];
}
