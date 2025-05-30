import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/device/device_status.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/canvas_notification_manager.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BluetoothDeviceManager {
  factory BluetoothDeviceManager() => _instance;
  // make singleton

  BluetoothDeviceManager._();

  static final BluetoothDeviceManager _instance = BluetoothDeviceManager._();

  static CloudDB get _ffDeviceDB => injector<CloudManager>().ffDeviceDB;

  static List<FFBluetoothDevice> get pairedDevices {
    final rawData = _ffDeviceDB.values;
    final devices = rawData
        .map((e) =>
            FFBluetoothDevice.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
        .cast<FFBluetoothDevice>();
    return devices
        .toSet()
        .toList()
        .where(
          (device) => device.deviceId.isNotEmpty,
        )
        .toList();
  }

  Future<void> deleteAllDevices() async {
    await _ffDeviceDB.deleteAll();
    _castingBluetoothDevice = null;
    await CanvasNotificationManager().disconnectAll();
  }

  Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await deleteAllDevices();

    await _ffDeviceDB.write([device.toKeyValue]);
    BluetoothDeviceManager().castingBluetoothDevice = device;
    await CanvasNotificationManager().connect(device);
    log.info(
      'BluetoothDeviceHelper.addDevice: added ${device.toJson()}',
    );
  }

  // Casting device status
  final ValueNotifier<DeviceStatus?> _castingDeviceStatus = ValueNotifier(null);

  ValueNotifier<DeviceStatus?> get castingDeviceStatus {
    if (_castingDeviceStatus.value == null &&
        castingBluetoothDevice != null) {}
    return _castingDeviceStatus;
  }

  // Casting device info
  FFBluetoothDevice? _castingBluetoothDevice;

  set castingBluetoothDevice(FFBluetoothDevice? device) {
    final state = injector<CanvasDeviceBloc>().state;
    if (device == null) {
      _castingBluetoothDevice = null;
      return;
    }
    if (!state.isDeviceAlive(device)) {
      return;
    }

    if (device == _castingBluetoothDevice) {
      return;
    }

    _castingBluetoothDevice = device;
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    final state = injector<CanvasDeviceBloc>().state;
    if (_castingBluetoothDevice != null) {
      if (state.isDeviceAlive(_castingBluetoothDevice!)) {
        return _castingBluetoothDevice;
      }
    }

    final device = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
      state.isDeviceAlive,
    );
    if (device != null) {
      castingBluetoothDevice = device;
      return device;
    }
    _castingBluetoothDevice = null;
    return null;
  }
}
