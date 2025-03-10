import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectEvent {}

class BluetoothConnectEventUpdateBluetoothState extends BluetoothConnectEvent {
  BluetoothConnectEventUpdateBluetoothState(this.bluetoothAdapterState);

  final BluetoothAdapterState bluetoothAdapterState;
}

class BluetoothConnectState {
  BluetoothConnectState({
    this.bluetoothAdapterState = BluetoothAdapterState.unknown,
  });

  final BluetoothAdapterState bluetoothAdapterState;

  BluetoothConnectState copyWith({
    BluetoothAdapterState? bluetoothAdapterState,
  }) {
    return BluetoothConnectState(
      bluetoothAdapterState:
          bluetoothAdapterState ?? this.bluetoothAdapterState,
    );
  }
}
