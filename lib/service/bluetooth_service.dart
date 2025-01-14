import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry.dart';

class FFBluetoothService {
  FFBluetoothService();

  // connected device
  FFBluetoothDevice? _connectedDevice;

  Box<FFBluetoothDevice> get _pairedDevicesBox =>
      ObjectBox.bluetoothPairedDevicesBox;

  set connectedDevice(BluetoothDevice? device) {
    final ffdevice = FFBluetoothDevice(
      remoteId: device!.id.toString(),
      name: device.name,
    );
    _connectedDevice = ffdevice;
  }

  FFBluetoothDevice? get connectedDevice => _connectedDevice;

  // characteristic for sending commands to Peripheral
  BluetoothCharacteristic? _commandCharacteristic;

  // characteristic to send Wi-Fi credentials to Peripheral
  BluetoothCharacteristic? _wifiConnectCharacteristic;

  set commandCharacteristic(BluetoothCharacteristic? characteristic) {
    _commandCharacteristic = characteristic;
  }

  set wifiConnectCharacteristic(BluetoothCharacteristic? characteristic) {
    _wifiConnectCharacteristic = characteristic;
  }

  String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  String wifiConnectCharUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // wifi connect characteristic

  Future<void> sendCommand({
    required String command,
    required Map<String, dynamic> request,
  }) async {
    log.info('[sendCommand] Sending command: $command');
    // Check if the device is connected
    if (_connectedDevice == null) {
      return;
    }

    // Check if the device is connected
    if (!_connectedDevice!.isConnected) {
      await connectToDevice(_connectedDevice as BluetoothDevice);
      if (!_connectedDevice!.isConnected) {
        return;
      }
    }

    // Check if the command characteristic is available
    if (_commandCharacteristic == null) {
      return;
    }

    final commandBytes = utf8.encode(command);

    final bodyString = json.encode(request);
    // Convert credentials to ASCII bytes
    final bodyBytes = ascii.encode(bodyString);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder()
      // Write command length as varint
      ..writeVarint(command.length)
      // Write command bytes
      ..add(commandBytes)

      // Write SSID length as varint
      ..writeVarint(bodyBytes.length)
      // Write SSID bytes
      ..add(bodyBytes);

    // Write the data to the characteristic
    final bytes = builder.takeBytes();
    final bytesInHex = bytes.map((e) => e.toRadixString(16)).join(' ');
    log.info('[sendCommand] Sending bytes: $bytesInHex');
    try {
      await _commandCharacteristic!
          .write(bytes, withoutResponse: false, allowLongWrite: true);
      log.info('[sendCommand] Command sent');
    } catch (e) {
      Sentry.captureException(e);
      log.info('[sendCommand] Error sending command: $e');
    }
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    // Check if the device is connected
    if (_connectedDevice == null) {
      return;
    }

    // Check if the device is connected
    if (!_connectedDevice!.isConnected) {
      await connectToDevice(_connectedDevice as BluetoothDevice);
      if (!_connectedDevice!.isConnected) {
        return;
      }
    }

    // Check if the wifi connect characteristic is available
    if (_wifiConnectCharacteristic == null) {
      return;
    }

    // Convert SSID and password to ASCII bytes
    final ssidBytes = ascii.encode(ssid);
    final passwordBytes = ascii.encode(password);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder()
      // Write SSID length as varint
      ..writeVarint(ssidBytes.length)
      // Write SSID bytes
      ..add(ssidBytes)

      // Write password length as varint
      ..writeVarint(passwordBytes.length)
      // Write password bytes
      ..add(passwordBytes);

    // Write the data to the characteristic
    final bytes = builder.takeBytes();
    final bytesInHex = bytes.map((e) => e.toRadixString(16)).join(' ');
    log.info('[sendWifiCredentials] Sending bytes: $bytesInHex');
    try {
      await _wifiConnectCharacteristic!.write(bytes, withoutResponse: false);
      log.info('[sendWifiCredentials] Wi-Fi credentials sent');
    } catch (e) {
      Sentry.captureException(e);
      log.info('[sendWifiCredentials] Error sending Wi-Fi credentials: $e');
    }
  }

  Future<void> autoReConnect() async {
    final pairedDevices = BluetoothDeviceHelper.pairedDevices;
    if (pairedDevices.isEmpty) {
      return;
    }
    final remoteId = pairedDevices.first.deviceId;
    final device = FlutterBluePlus.connectedDevices
        .firstWhereOrNull((element) => element.id.toString() == remoteId);
    if (device != null) {
      await connectToDevice(device);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    final services = await device.discoverServices();
    final commandService = services.firstWhere(
      (service) =>
          service.uuid.toString() == '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
    );
    final commandChar = commandService.characteristics.firstWhere(
      (characteristic) => characteristic.uuid.toString() == commandCharUuid,
    );
    final wifiConnectChar = commandService.characteristics.firstWhere(
      (characteristic) => characteristic.uuid.toString() == wifiConnectCharUuid,
    );
    // Set the command and wifi connect characteristics
    commandCharacteristic = commandChar;
    wifiConnectCharacteristic = wifiConnectChar;
  }

// Future<StreamSubscription> startScan({FutureOr<void> Function()? onStart, FutureOr<void> Function()? onStop, FutureOr<void> Function()? onError,}) async {
//   _addLog("Starting BLE scan...");
//
//   await onStart?.call();
//
//   final StreamSubscription scanSubscription = FlutterBluePlus.onScanResults.listen(
//         (results) {
//       for (ScanResult r in results) {
//         _addLog('Device found: ${r.device.name} (${r.device.id.id})');
//         _addLog('  Service UUIDs: ${r.advertisementData.serviceUuids}');
//         log.info('Found device: ${r.device.name}, ID: ${r.device.id.id}');
//       }
//
//       // Filter results to only include devices advertising our service UUID
//       final filteredResults = results.where((result) {
//         return result.advertisementData.serviceUuids
//             .map((uuid) => uuid.toString().toLowerCase())
//             .contains(advertisingUuid.toLowerCase());
//       }).toList();
//
//       setState(() {
//         scanResults = filteredResults;
//       });
//     },
//     onError: (error) {
//       _addLog('Error during scan: $error');
//       await onError?.call();
//     },
//   );
//
//   FlutterBluePlus.startScan(
//     timeout: const Duration(seconds: 60), // Updated to 60 seconds
//     androidUsesFineLocation: true,
//   );
//   return scanSubscription;
// }
}
