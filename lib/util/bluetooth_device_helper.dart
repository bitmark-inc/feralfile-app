import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/device/device_status.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/canvas_notification_manager.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
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

  Future<void> resetDevice() async {
    BluetoothDeviceManager().castingBluetoothDevice = null;
    await CanvasNotificationManager().disconnectAll();
  }

  Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await _setupDevice(device, shouldWriteToDb: true);
    log.info(
      'BluetoothDeviceHelper.addDevice: added ${device.toJson()}',
    );
  }

  Future<void> switchDevice(
    FFBluetoothDevice device,
  ) async {
    await _setupDevice(device, shouldWriteToDb: false);
    log.info(
      'BluetoothDeviceHelper.switchDevice: switched to ${device.toJson()}',
    );
  }

  Future<void> _setupDevice(
    FFBluetoothDevice device, {
    required bool shouldWriteToDb,
  }) async {
    await resetDevice();

    if (shouldWriteToDb) {
      await _ffDeviceDB.write([device.toKeyValue]);
    }

    BluetoothDeviceManager().castingBluetoothDevice = device;
    await CanvasNotificationManager().connect(device);
  }

  // Casting device status
  final ValueNotifier<DeviceStatus?> _castingDeviceStatus = ValueNotifier(null);

  ValueNotifier<DeviceStatus?> get castingDeviceStatus {
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

    injector<ConfigurationService>().setSelectedDeviceId(device.deviceId);
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }

    final selectedDeviceId =
        injector<ConfigurationService>().getSelectedDeviceId();
    if (selectedDeviceId != null) {
      final device = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
        (device) => device.deviceId == selectedDeviceId,
      );
      if (device != null) {
        castingBluetoothDevice = device;
        return device;
      }
    }

    return null;
  }
}
