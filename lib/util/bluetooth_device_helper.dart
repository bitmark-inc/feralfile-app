import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

class BluetoothDeviceHelper {
  // make singleton

  BluetoothDeviceHelper._();

  static final BluetoothDeviceHelper _instance = BluetoothDeviceHelper._();

  factory BluetoothDeviceHelper() => _instance;

  static Box<FFBluetoothDevice> get _pairedDevicesBox =>
      ObjectBox.bluetoothPairedDevicesBox;

  static List<FFBluetoothDevice> get pairedDevices {
    final devices = _pairedDevicesBox.getAll();
    return devices.toSet().toList();
  }

  static Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await _pairedDevicesBox.removeAllAsync();
    await _pairedDevicesBox.putAsync(device);
    BluetoothDeviceHelper().castingBluetoothDevice = device;
    injector<CanvasDeviceBloc>().add(
      CanvasDeviceGetDevicesEvent(),
    );
  }

  // connected device
  FFBluetoothDevice? _castingBluetoothDevice;
  final ValueNotifier<BluetoothDeviceStatus?> _bluetoothDeviceStatus =
      ValueNotifier(null);

  ValueNotifier<BluetoothDeviceStatus?> get bluetoothDeviceStatus {
    if (_bluetoothDeviceStatus.value == null &&
        castingBluetoothDevice != null) {
      _fetchBluetoothDeviceStatus(castingBluetoothDevice!);
    }
    return _bluetoothDeviceStatus;
  }

  set castingBluetoothDevice(FFBluetoothDevice? device) {
    if (device == null) {
      _castingBluetoothDevice = null;
      Sentry.captureException('Set Casting device value to null');
      return;
    }
    if (device.deviceId == _castingBluetoothDevice?.deviceId) {
      return;
    }
    _castingBluetoothDevice = device;
    _fetchBluetoothDeviceStatus(device);
  }

  Future<void> _fetchBluetoothDeviceStatus(FFBluetoothDevice device) async {
    try {
      final status = await injector<FFBluetoothService>()
          .fetchBluetoothDeviceStatus(device);
      _bluetoothDeviceStatus.value = status;
    } catch (e, stackTrace) {
      Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }

    final device = BluetoothDeviceHelper.pairedDevices.firstOrNull;
    if (device != null) {
      castingBluetoothDevice = device;
    }
    return _castingBluetoothDevice;
  }
}
