import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry.dart';

class FFBluetoothService {
  FFBluetoothService() {}

  Future<void> init() async {
    if (!(await FlutterBluePlus.isSupported)) {
      log.info('Bluetooth is not supported');
      injector<BluetoothConnectBloc>().add(
        BluetoothConnectEventUpdateBluetoothState(
          BluetoothAdapterState.unavailable,
        ),
      );
      return;
    }

    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState bluetoothState) {
      _bluetoothAdapterState = bluetoothState;
      injector<BluetoothConnectBloc>()
          .add(BluetoothConnectEventUpdateBluetoothState(bluetoothState));
    });
  }

  // connected device
  FFBluetoothDevice? _connectedDevice;

  set connectedDevice(BluetoothDevice? device) {
    final ffdevice = FFBluetoothDevice(
      remoteID: device!.remoteId.str,
      name: device.advName,
    );
    _connectedDevice = ffdevice;
    BluetoothDeviceHelper.saveLastConnectedDevice(ffdevice);
  }

  FFBluetoothDevice? get connectedDevice =>
      _connectedDevice ??
      BluetoothDeviceHelper.getLastConnectedDevice(checkAvailability: true);

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  bool get isBluetoothOn => _bluetoothAdapterState == BluetoothAdapterState.on;

  final String advertisingUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  // For scanning
  final String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  String wifiConnectCharUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // wifi connect characteristic

  StreamSubscription<List<int>>? _commandCharSub;

  // characteristic for sending commands to Peripheral
  Map<String, BluetoothCharacteristic> _commandCharacteristic = {};

  // characteristic to send Wi-Fi credentials to Peripheral
  Map<String, BluetoothCharacteristic> _wifiConnectCharacteristic = {};

  void setCommandCharacteristic(BluetoothCharacteristic characteristic) {
    _commandCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  void clearCommandCharacteristic({required String remoteId}) {
    _commandCharacteristic.remove(remoteId);
  }

  void setWifiConnectCharacteristic(BluetoothCharacteristic characteristic) {
    _wifiConnectCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  void clearWifiConnectCharacteristic({required String remoteId}) {
    _wifiConnectCharacteristic.remove(remoteId);
  }

  BluetoothCharacteristic? getCommandCharacteristic(String remoteId) =>
      _commandCharacteristic[remoteId];

  BluetoothCharacteristic? getWifiConnectCharacteristic(String remoteId) =>
      _wifiConnectCharacteristic[remoteId];

  Future<Map<String, dynamic>> sendCommand({
    required BluetoothDevice device,
    required String command,
    required Map<String, dynamic> request,
  }) async {
    log.info(
        '[sendCommand] Sending command: $command to device: ${device.remoteId.str}');

    // Check if the device is connected
    if (!device.isConnected) {
      await connectToDevice(device);
      await device.discoverServices();
      if (!device.isConnected) {
        throw Exception('Device not connected after reconnection');
      }
    }
    final commandChar = getCommandCharacteristic(device.remoteId.str);
    // Check if the command characteristic is available
    if (commandChar == null) {
      throw Exception('Command characteristic not found');
    }

    // Generate random 4 char replyId
    final replyId = String.fromCharCodes(
      List.generate(4, (_) => Random().nextInt(26) + 97),
    );

    final commandBytes = ascii.encode(command);
    final bodyString = json.encode(request);
    final bodyBytes = ascii.encode(bodyString);
    final replyIdBytes = ascii.encode(replyId);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder()
      // Write command length as varint
      ..writeVarint(command.length)
      // Write command bytes
      ..add(commandBytes)
      // Write body length as varint
      ..writeVarint(bodyBytes.length)
      // Write body bytes
      ..add(bodyBytes)
      // Write replyId length as varint
      ..writeVarint(replyIdBytes.length)
      // Write replyId bytes
      ..add(replyIdBytes);

    // Write the data to the characteristic
    final bytes = builder.takeBytes();
    final bytesInHex = bytes.map((e) => e.toRadixString(16)).join(' ');
    log.info('[sendCommand] Sending bytes: $bytesInHex');

    // Create a completer to wait for the reply
    final completer = Completer<Map<String, dynamic>>();

    // Subscribe to notifications for this replyId
    BluetoothNotificationService().subscribe(replyId, (data) {
      completer.complete(data);
      // Unsubscribe after getting the reply
      BluetoothNotificationService().unsubscribe(replyId, (data) {});
    });

    try {
      await commandChar.write(bytes, withoutResponse: true);
      log.info('[sendCommand] Command $command sent');

      // Wait for reply with timeout
      return await completer.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          BluetoothNotificationService().unsubscribe(replyId, (data) {
            log.info('[sendCommand] Unsubscribed from replyId: $replyId');
          });
          Sentry.captureMessage(
            '[sendCommand] Timeout waiting for reply: $replyId',
          );
          return fakeReply(command)
              .toJson(); // Fallback to fake reply on timeout
        },
      );
    } catch (e) {
      BluetoothNotificationService().unsubscribe(replyId, (data) {});
      unawaited(Sentry.captureException(e));
      log.info('[sendCommand] Error sending command: $e');
      rethrow;
    }
  }

  Future<void> sendWifiCredentials({
    required BluetoothDevice device,
    required String ssid,
    required String password,
  }) async {
    // Check if the device is connected
    if (!device.isConnected) {
      await connectToDevice(device);
      if (!device.isConnected) {
        return;
      }
    }

    final wifiConnectChar = getWifiConnectCharacteristic(device.remoteId.str);
    // Check if the wifi connect characteristic is available
    if (wifiConnectChar == null) {
      log.warning('Wi-Fi connect characteristic not found');
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
      await wifiConnectChar.write(bytes, withoutResponse: false);
      log.info('[sendWifiCredentials] Wi-Fi credentials sent');
    } catch (e) {
      Sentry.captureException(e);
      log.info('[sendWifiCredentials] Error sending Wi-Fi credentials: $e');
    }
  }

  Future<void> connectToDeviceIfPaired(BluetoothDevice device) async {
    final isDevicePaired = BluetoothDeviceHelper.isDeviceSaved(device);
    if (!isDevicePaired) {
      log.warning('Device not paired: ${device.remoteId.str}');
      return;
    }

    final connectedDevice = injector<FFBluetoothService>().connectedDevice;
    if (connectedDevice == null ||
        connectedDevice.remoteID == device.remoteId.str) {
      await connectToDevice(device);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    List<BluetoothService> services = [];
    if (device.isDisconnected) {
      final connectCompleter = Completer<void>();

      log.info('Connecting to device: ${device.remoteId.str}');
      final subscription = device.connectionState.listen((state) {
        log.info(
          'Connection state update for ${device.remoteId.str}: ${state.name}',
        );
        if (state == BluetoothConnectionState.connected) {
          connectCompleter.complete();
        }
        if (state == BluetoothConnectionState.disconnected) {
          log.warning('Device disconnected reason: ${device.disconnectReason}');
        }
      });

      device.cancelWhenDisconnected(subscription, delayed: true, next: true);

      try {
        await device.connect();
      } catch (e) {
        log.warning('Failed to connect to device: $e');
        rethrow;
      }

      await connectCompleter.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log.warning('Connection timeout');
          return;
        },
      );

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
      name: device.advName,
    );

    //if device connected, add to objectbox
    await BluetoothDeviceHelper.addDevice(
      FFBluetoothDevice(
        remoteID: device.remoteId.str,
        name: device.advName,
      ),
    );

    if (getCommandCharacteristic(device.remoteId.str) == null ||
        getWifiConnectCharacteristic(device.remoteId.str) == null) {
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
        (characteristic) =>
            characteristic.uuid.toString() == wifiConnectCharUuid,
      );
      // Set the command and wifi connect characteristics
      setCommandCharacteristic(commandChar);
      setWifiConnectCharacteristic(wifiConnectChar);
    }

    final commandCharacteristic = getCommandCharacteristic(device.remoteId.str);

    if (commandCharacteristic == null) {
      log.warning('Command characteristic not found');
      return;
    }

    log.info('Command char properties: ${commandCharacteristic.properties}');
    if (!commandCharacteristic.properties.notify) {
      log.warning('Command characteristic does not support notifications!');
      return;
    }

    try {
      await commandCharacteristic.setNotifyValue(true);
      log.info('Successfully enabled notifications for command char');
    } catch (e) {
      log.warning('Failed to enable notifications for command char: $e');
      Sentry.captureException(e);
      return;
    }

    final commandCharSub = commandCharacteristic.onValueReceived.listen(
      (value) {
        log.info('Received data from command characteristic: $value');
        BluetoothNotificationService().handleNotification(value);
      },
      onError: (error) {
        log.warning('Error in command char subscription: $error');
        Sentry.captureException(error);
      },
    );

    device.cancelWhenDisconnected(commandCharSub, delayed: true);
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 30),
    FutureOr<bool> Function(List<ScanResult>)? onData,
    FutureOr<void> Function(dynamic)? onError,
  }) async {
    if (!injector<AuthService>().isBetaTester()) {
      return;
    }
    StreamSubscription<List<ScanResult>>? scanSubscription;

    // if (state.bluetoothAdapterState != BluetoothAdapterState.on) {
    //   log.info('BluetoothConnectEventScan BluetoothAdapterState is not on');
    //   return;
    // }
    scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) async {
        final shouldStopScan = await onData?.call(results);
        if (shouldStopScan == true) {
          FlutterBluePlus.stopScan();
        }
      },
      onError: (error) {
        onError?.call(error);
        scanSubscription?.cancel();
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(scanSubscription);
    log.info('BluetoothConnectEventScan startScan');
    await FlutterBluePlus.startScan(
      timeout: timeout, // Updated to 60 seconds
      androidUsesFineLocation: true,
      withServices: [
        Guid(injector<FFBluetoothService>().serviceUuid),
      ],
    );
    // wait for scan to complete
    while (FlutterBluePlus.isScanningNow) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  Future<void> findCharacteristics(BluetoothDevice devices) async {
    final List<BluetoothService> services = await devices.discoverServices();
    for (var service in services) {
      log.info(
        'Discovered service UUID: ${service.uuid.toString().toLowerCase()}',
      );
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (final characteristic in service.characteristics) {
          log.info(
            'Found characteristic UUID: '
            '${characteristic.uuid.toString().toLowerCase()}',
          );

          if (characteristic.uuid.toString().toLowerCase() == commandCharUuid) {
            setCommandCharacteristic(characteristic);
            log.info('Found command characteristic');
          }
          // if the characteristic UUID matches the target characteristic UUID
          if (characteristic.uuid.toString().toLowerCase() ==
              wifiConnectCharUuid) {
            setWifiConnectCharacteristic(characteristic);

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
      case CastCommand.sendLog:
        return SendLogReply(
          ok: true,
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
