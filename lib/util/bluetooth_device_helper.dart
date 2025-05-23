import 'dart:async';

import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

class BluetoothDeviceManager {
  // make singleton

  BluetoothDeviceManager._();

  static final BluetoothDeviceManager _instance = BluetoothDeviceManager._();

  factory BluetoothDeviceManager() => _instance;

  static Box<FFBluetoothDevice> get _pairedDevicesBox =>
      ObjectBox.bluetoothPairedDevicesBox;

  static List<FFBluetoothDevice> get pairedDevices {
    final devices = _pairedDevicesBox.getAll();
    return devices
        .toSet()
        .toList()
        .where(
          (device) => device.deviceId.isNotEmpty,
        )
        .toList();
  }

  static Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await _pairedDevicesBox.removeAllAsync();
    await _pairedDevicesBox.putAsync(device);
    BluetoothDeviceManager().castingBluetoothDevice = device;
    injector<CanvasDeviceBloc>().add(
      CanvasDeviceGetDevicesEvent(),
    );
    log.info(
      'BluetoothDeviceHelper.addDevice: added ${device.toJson()}',
    );
  }

  // connected device
  FFBluetoothDevice? _castingBluetoothDevice;
  final ValueNotifier<BluetoothDeviceStatus?> _bluetoothDeviceStatus =
      ValueNotifier(null);

  ValueNotifier<BluetoothDeviceStatus?> get bluetoothDeviceStatus {
    if (_bluetoothDeviceStatus.value == null &&
        castingBluetoothDevice != null) {
      fetchBluetoothDeviceStatus(castingBluetoothDevice!);
    }
    return _bluetoothDeviceStatus;
  }

  set castingBluetoothDevice(FFBluetoothDevice? device) {
    if (device == null) {
      _castingBluetoothDevice = null;
      Sentry.captureException('Set Casting device value to null');
      return;
    }
    if (device == _castingBluetoothDevice) {
      return;
    }
    _castingBluetoothDevice = device;
    fetchBluetoothDeviceStatus(device);
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }

    final device = BluetoothDeviceManager.pairedDevices.firstOrNull;
    if (device != null) {
      castingBluetoothDevice = device;
    }
    return _castingBluetoothDevice;
  }

  Future<BluetoothDeviceStatus?> fetchBluetoothDeviceStatus(
      BaseDevice device) async {
    try {
      final status = await injector<CanvasClientServiceV2>()
          .getBluetoothDeviceStatus(device);
      _bluetoothDeviceStatus.value = status;
      return status;
    } catch (e, stackTrace) {
      Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      log.info(
        'BluetoothDeviceHelper.fetchBluetoothDeviceStatus: error $e',
      );
      return null;
    }
  }

  Timer? _statusPullTimer;

  void startStatusPull() {
    _statusPullTimer?.cancel();
    _statusPullTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        injector<CanvasDeviceBloc>().add(
          CanvasDeviceGetDevicesEvent(),
        );
        // await NowDisplayingManager().updateDisplayingNow(addStatusOnError: false);
      },
    );
  }

  void stopStatusPull() {
    _statusPullTimer?.cancel();
    _statusPullTimer = null;
  }
}
