import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  // For scanning
  static String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

// command characteristic
  static String commandCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

// wifi connect characteristic
  static String wifiConnectCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  // Add this constant for the engineering mode characteristic UUID
  static String engineeringCharUuid = '6e400004-b5a3-f393-e0a9-e50e24dcca9e';

// characteristic for sending commands to Peripheral
  static final _commandCharacteristic = <String, BluetoothCharacteristic>{};

// characteristic to send Wi-Fi credentials to Peripheral
  static final _wifiConnectCharacteristic = <String, BluetoothCharacteristic>{};

  static final _engineeringCharacteristic = <String, BluetoothCharacteristic>{};

  static void setCommandCharacteristic(BluetoothCharacteristic characteristic) {
    log.info('Setting command characteristic: ${characteristic.uuid}');
    _commandCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  static void setWifiConnectCharacteristic(
      BluetoothCharacteristic characteristic) {
    log.info('Setting Wi-Fi connect characteristic: ${characteristic.uuid}');
    _wifiConnectCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  static void setEngineeringCharacteristic(
      BluetoothCharacteristic characteristic) {
    _engineeringCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  static BluetoothCharacteristic? getCommandCharacteristic(String remoteId) {
    final char = _commandCharacteristic[remoteId];
    if (char == null) {
      log.warning('Command characteristic not found for remoteId: $remoteId');
    } else {
      log.info('Command characteristic found for remoteId: $remoteId');
    }
    return char;
  }

  static BluetoothCharacteristic? getWifiConnectCharacteristic(
          String remoteId) =>
      _wifiConnectCharacteristic[remoteId];

  static BluetoothCharacteristic? getEngineeringCharacteristic(
          String remoteId) =>
      _engineeringCharacteristic[remoteId];
}
