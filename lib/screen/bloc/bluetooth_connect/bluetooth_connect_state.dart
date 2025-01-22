import 'dart:async';

import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectEvent {}

class BluetoothConnectEventScan extends BluetoothConnectEvent {}

class BluetoothConnectEventStopScan extends BluetoothConnectEvent {}

class BluetoothConnectEventGetBluetoothStatus extends BluetoothConnectEvent {}

class BluetoothConnectEventUpdateBluetoothState extends BluetoothConnectEvent {
  BluetoothConnectEventUpdateBluetoothState(this.bluetoothAdapterState);

  final BluetoothAdapterState bluetoothAdapterState;
}

class BluetoothConnectEventConnect extends BluetoothConnectEvent {
  BluetoothConnectEventConnect({
    required this.device,
    this.onConnectSuccess,
    this.onConnectFailure,
  });

  final BluetoothDevice device;

  final FutureOr<void> Function(BluetoothDevice device)? onConnectSuccess;
  final FutureOr<void> Function(BluetoothDevice device)? onConnectFailure;
}

class BluetoothConnectState {
  BluetoothConnectState({
    this.device,
    this.error,
    this.isScanning = false,
    this.connectingDevice,
    this.connectedDevice,
    this.pairedDevices = const [],
    this.scanResults = const [],
    this.bluetoothAdapterState = BluetoothAdapterState.unknown,
  });

  final BluetoothAdapterState bluetoothAdapterState;
  final BluetoothDevice? device;
  final String? error;
  final bool isScanning;
  final BluetoothDevice? connectingDevice;
  final BluetoothDevice? connectedDevice;

  final List<BluetoothDevice> pairedDevices;
  final List<ScanResult> scanResults;

  BluetoothConnectState copyWith({
    BluetoothDevice? device,
    String? error,
    bool? isScanning,
    BluetoothDevice? connectingDevice,
    bool shouldOverrideConnectingDevice = false,
    BluetoothDevice? connectedDevice,
    List<BluetoothDevice>? pairedDevices,
    List<ScanResult>? scanResults,
    BluetoothAdapterState? bluetoothAdapterState,
  }) {
    log.info(
        'BluetoothConnectState copyWith ${bluetoothAdapterState ?? this.bluetoothAdapterState}');
    if ((bluetoothAdapterState ?? this.bluetoothAdapterState) ==
        BluetoothAdapterState.on) {
      log.info('BluetoothConnectState copyWith on');
    }
    return BluetoothConnectState(
      device: device ?? this.device,
      error: error ?? this.error,
      isScanning: isScanning ?? this.isScanning,
      connectingDevice: shouldOverrideConnectingDevice
          ? connectingDevice
          : connectingDevice ?? this.connectingDevice,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      scanResults: scanResults ?? this.scanResults,
      bluetoothAdapterState:
          bluetoothAdapterState ?? this.bluetoothAdapterState,
    );
  }
}

extension BluetoothConnectStateExtension on BluetoothConnectState {
  List<FFBluetoothDevice> get scanedDevices {
    return scanResults
        .map((result) => FFBluetoothDevice(
            name: result.device.advName, remoteID: result.device.remoteId.str))
        .toList();
  }
}
