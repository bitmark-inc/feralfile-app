import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  BluetoothCharacteristic? wifiConnectCharacteristic;

  set commandCharacteristic(BluetoothCharacteristic? characteristic) {
    _commandCharacteristic = characteristic;
  }

  String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  Future<void> sendCommand({required Map<String, dynamic> body}) async {
    if (_commandCharacteristic == null) {
      return;
    }

    final bodyString = json.encode(body);

    // Convert credentials to ASCII bytes
    final bodyBytes = ascii.encode(bodyString);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder()

      // Write SSID length as varint
      ..writeVarint(bodyBytes.length)
      // Write SSID bytes
      ..add(bodyBytes);

    // Write the data to the characteristic
    await _commandCharacteristic!
        .write(builder.takeBytes(), withoutResponse: false);
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
    final commandCharacteristic = commandService.characteristics.firstWhere(
      (characteristic) => characteristic.uuid.toString() == commandCharUuid,
    );
    commandCharacteristic.setNotifyValue(true);
    commandCharacteristic.value.listen((value) {});
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
