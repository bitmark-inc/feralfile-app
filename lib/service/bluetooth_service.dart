import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
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
      remoteID: device!.id.toString(),
      name: device.name,
    );
    _connectedDevice = ffdevice;
    BluetoothDeviceHelper.saveLastConnectedDevice(ffdevice);
  }

  FFBluetoothDevice? get connectedDevice =>
      _connectedDevice ??
      BluetoothDeviceHelper.getLastConnectedDevice(checkAvailability: true);

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

  BluetoothCharacteristic? get commandCharacteristic => _commandCharacteristic;

  BluetoothCharacteristic? get wifiConnectCharacteristic =>
      _wifiConnectCharacteristic;

  Map<String, Stream<BluetoothConnectionState>> _connectionStateStreams = {};

  final String advertisingUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  // For scanning
  final String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  String wifiConnectCharUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // wifi connect characteristic

  Future<Map<String, dynamic>> sendCommand({
    required String command,
    required Map<String, dynamic> request,
  }) async {
    log.info('[sendCommand] Sending command: $command');

    final device = connectedDevice;

    // Check if the device is connected
    if (device == null) {
      throw Exception('No connected device');
    }

    // Check if the device is connected
    if (!device.isConnected) {
      await connectToDevice(device as BluetoothDevice);
      await device.discoverServices();
      if (!device.isConnected) {
        throw Exception('Device not connected after reconnection');
      }
    }

    // Check if the command characteristic is available
    if (_commandCharacteristic == null) {
      throw Exception('Command characteristic not found');
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
      await _commandCharacteristic!.write(bytes, withoutResponse: false);
      log.info('[sendCommand] Command sent');
      return fakeReply(command).toJson();
    } catch (e) {
      Sentry.captureException(e);
      log.info('[sendCommand] Error sending command: $e');
      throw e;
    }
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    // Check if the device is connected
    final device = connectedDevice;

    if (device == null) {
      return;
    }

    // Check if the device is connected
    if (!device!.isConnected) {
      await connectToDevice(device as BluetoothDevice);
      if (!device!.isConnected) {
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
    List<BluetoothService> services = [];
    if (device.isDisconnected) {
      log.info('Connecting to device: ${device.remoteId.str}');
      final subscription = device.connectionState.listen((state) {
        log.info(
            'Connection state update for ${device.remoteId.str}: ${state.name}');
      });

      final bondSubscription = device.bondState.listen((state) {
        log.info('Bond state update for ${device.remoteId.str}: ${state.name}');
      });

      device.cancelWhenDisconnected(subscription, delayed: true, next: true);
      device.cancelWhenDisconnected(bondSubscription,
          delayed: true, next: true);
      await device.connect();
      // Discover services
      // Note: You must call discoverServices after every re-connection!
      final discoveredServices = await device.discoverServices();
      services.clear();
      services.addAll(discoveredServices);
    } else {
      log.info('Device already connected: ${device.remoteId.str}');
    }

    // if connect to the same device, return
    // if (connectedDevice?.remoteId.str == device.remoteId.str) {
    //   return;
    // }

    connectedDevice = FFBluetoothDevice(
      remoteID: device.remoteId.str,
      name: device.platformName,
    );

    //if device connected, add to objectbox
    BluetoothDeviceHelper.addDevice(FFBluetoothDevice(
      remoteID: device.id.toString(),
      name: device.name,
    ));

    if (commandCharacteristic != null && wifiConnectCharacteristic != null) {
      return;
    }

    final commandService = services.firstWhereOrNull(
      (service) => service.uuid.toString() == serviceUuid,
    );
    if (commandService == null) {
      Sentry.captureMessage('Command service not found');
      return;
    }
    final commandChar = commandService.characteristics.firstWhere(
      (characteristic) => characteristic.uuid.toString() == commandCharUuid,
    );
    final wifiConnectChar = commandService.characteristics.firstWhere(
      (characteristic) => characteristic.uuid.toString() == wifiConnectCharUuid,
    );
    // Set the command and wifi connect characteristics
    commandCharacteristic = commandChar;
    wifiConnectCharacteristic = wifiConnectChar;

    final commandCharSub = commandChar.onValueReceived.listen((value) {
      final receivedText = utf8.decode(value);
      log.info('Received data from command characteristic: $receivedText');
    });
    final wifiConnectCharSub = wifiConnectChar.onValueReceived.listen((value) {
      final receivedText = utf8.decode(value);
      log.info('Received data from wifi connect characteristic: $receivedText');
    });

    device.cancelWhenDisconnected(commandCharSub, delayed: true);
    device.cancelWhenDisconnected(wifiConnectCharSub, delayed: true);

    await commandChar.setNotifyValue(true);
    await wifiConnectChar.setNotifyValue(true);
  }

  Future<void> findCharacteristics(BluetoothDevice devices) async {
    final List<BluetoothService> services = await devices.discoverServices();
    for (var service in services) {
      log.info(
          'Discovered service UUID: ${service.uuid.toString().toLowerCase()}');
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          log.info(
            'Found characteristic UUID: ${characteristic.uuid.toString().toLowerCase()}',
          );

          if (characteristic.uuid.toString().toLowerCase() == commandCharUuid) {
            commandCharacteristic = characteristic;
            log.info('Found command characteristic');
          }
          // if the characteristic UUID matches the target characteristic UUID
          if (characteristic.uuid.toString().toLowerCase() ==
              wifiConnectCharUuid) {
            wifiConnectCharacteristic = characteristic;

            // Set up notifications
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                final receivedText = utf8.decode(value);
              });
            }

            // return; // Found what we need
          }
        }
      }
    }
  }

  Reply fakeReply(String commandString) {
    final command = CastCommand.fromString(commandString);

    switch (command) {
      case CastCommand.checkStatus:
        return CheckDeviceStatusReply(artworks: []);
      case CastCommand.castListArtwork:
        return CastListArtworkReply(
          ok: true,
        );
      case CastCommand.castDaily:
        return CastDailyWorkReply(
          ok: true,
        );
      case CastCommand.pauseCasting:
        return PauseCastingReply(
          ok: true,
        );
      case CastCommand.resumeCasting:
        return ResumeCastingReply(
          ok: true,
        );
      case CastCommand.nextArtwork:
        return NextArtworkReply(
          ok: true,
        );
      case CastCommand.previousArtwork:
        return PreviousArtworkReply(
          ok: true,
        );
      case CastCommand.updateDuration:
        return UpdateDurationReply(
          artworks: [],
        );
      case CastCommand.castExhibition:
        return CastExhibitionReply(
          ok: true,
        );
      case CastCommand.connect:
        return ConnectReplyV2(
          ok: true,
        );
      case CastCommand.disconnect:
        return DisconnectReplyV2(
          ok: true,
        );

      case CastCommand.sendKeyboardEvent:
        return KeyboardEventReply(
          ok: true,
        );
      case CastCommand.rotate:
        return RotateReply(
          degree: 1,
        );
      case CastCommand.tapGesture:
        return GestureReply(
          ok: true,
        );
      case CastCommand.dragGesture:
        return GestureReply(
          ok: true,
        );
      default:
        throw ArgumentError('Unknown command: $commandString');
    }
  }
}
