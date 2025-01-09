import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FFBluetoothService {
  // connected device
  static BluetoothDevice? _connectedDevice;

  static set connectedDevice(BluetoothDevice? device) {
    _connectedDevice = device;
  }

  static BluetoothDevice? get connectedDevice => _connectedDevice;

  // characteristic for sending commands to Peripheral
  static BluetoothCharacteristic? _commandCharacteristic;

  // TODO: Add command characteristic UUID
  static String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  static Future<void> sendCommand({required Map<String, dynamic> body}) async {
    if (_commandCharacteristic == null) {
      return;
    }

    final bodyString = json.encode(body);

    // Convert credentials to ASCII bytes
    final bodyBytes = ascii.encode(bodyString);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder();

    // Write SSID length as varint
    builder.writeVarint(bodyBytes.length);
    // Write SSID bytes
    builder.add(bodyBytes);

    // Write the data to the characteristic
    await _commandCharacteristic!
        .write(builder.takeBytes(), withoutResponse: false);
  }
}

extension BytesBuilderExtension on BytesBuilder {
  void writeVarint(int value) {
    while (value >= 0x80) {
      addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    addByte(value);
  }
}
