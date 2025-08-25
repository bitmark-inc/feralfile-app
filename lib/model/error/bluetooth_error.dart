// Custom error class for Bluetooth errors
import 'package:autonomy_flutter/model/error/error.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FFBluetoothError extends FFError {
  @override
  final String message;

  FFBluetoothError(this.message);

  @override
  String toString() => 'FFBluetoothError: $message';
}

class FFBluetoothDisconnectedError extends FFBluetoothError {
  FFBluetoothDisconnectedError({
    this.disconnectReason,
  }) : super(
          'Bluetooth device disconnected: ${disconnectReason?.toString() ?? 'Unknown reason'}',
        );

  final DisconnectReason? disconnectReason;

  @override
  String toString() => 'FFBluetoothDisconnectedError: $message';
}
