import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectEvent {}

class BluetoothConnectEventScan extends BluetoothConnectEvent {}

class BluetoothConnectEventStopScan extends BluetoothConnectEvent {}

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
    this.isConnecting = false,
    this.connectedDevice,
    this.pairedDevices = const [],
    this.scanResults = const [],
  });

  final BluetoothDevice? device;
  final String? error;
  final bool isScanning;
  final bool isConnecting;
  final BluetoothDevice? connectedDevice;

  final List<BluetoothDevice> pairedDevices;
  final List<ScanResult> scanResults;

  BluetoothConnectState copyWith({
    BluetoothDevice? device,
    String? error,
    bool? isScanning,
    bool? isConnecting,
    BluetoothDevice? connectedDevice,
    List<BluetoothDevice>? pairedDevices,
    List<ScanResult>? scanResults,
  }) {
    return BluetoothConnectState(
      device: device ?? this.device,
      error: error ?? this.error,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      scanResults: scanResults ?? this.scanResults,
    );
  }
}
