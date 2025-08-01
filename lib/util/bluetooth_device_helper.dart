import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/device/device_status.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/service/canvas_notification_manager.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/device_realtime_metric_helper.dart';
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
    await _ffDeviceDB.write([device.toKeyValue]);
    log.info(
      'BluetoothDeviceHelper.addDevice: added ${device.toJson()}',
    );
    await switchDevice(device);
    log.info(
      'BluetoothDeviceHelper.addDevice: switched to ${device.toJson()}',
    );
  }

  Future<void> switchDevice(
    FFBluetoothDevice device,
  ) async {
    await _setupDevice(device, shouldWriteToDb: false);
    log.info(
      'BluetoothDeviceHelper.switchDevice: switched to ${device.toJson()}',
    );
    RealtimeMetricsManager().switchRealtimeMetrics(device);
  }

  Future<FFBluetoothDevice> updateDeviceName(
    FFBluetoothDevice device,
    String newName,
  ) async {
    final updatedDevice = device.copyWith(name: newName);
    await _ffDeviceDB.write([updatedDevice.toKeyValue]);
    log.info(
      'BluetoothDeviceHelper.updateDeviceName: updated ${device.toJson()} to ${updatedDevice.toJson()}',
    );
    return updatedDevice;
  }

  Future<void> removeDevice(String deviceId) async {
    await _ffDeviceDB.delete([deviceId]);
    if (BluetoothDeviceManager().castingBluetoothDevice?.deviceId != deviceId) {
      return;
    }
    // if casting device is removed, switch to another device
    final devices = pairedDevices;
    await resetDevice();
    if (devices.isNotEmpty) {
      await switchDevice(devices.first);
    } else {
      // if no device is paired, hide now displaying (like when user tap on close)
      shouldShowNowDisplayingOnDisconnect.value = false;
    }
  }

  FFBluetoothDevice? findDeviceByRemoteId(String remoteId) {
    final devices = pairedDevices;
    return devices.firstWhereOrNull((device) => device.remoteID == remoteId);
  }

  Future<void> _setupDevice(
    FFBluetoothDevice device, {
    required bool shouldWriteToDb,
  }) async {
    await resetDevice();

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
    if (device == null) {
      _castingBluetoothDevice = null;
      injector<ConfigurationService>().setSelectedDeviceId(null);
      injector<SettingsDataService>().backupUserSettings();
      return;
    }

    if (device == _castingBluetoothDevice) {
      return;
    }

    _castingBluetoothDevice = device;

    injector<ConfigurationService>().setSelectedDeviceId(device.deviceId);
    injector<SettingsDataService>().backupUserSettings();
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }

    final selectedDeviceId =
        injector<ConfigurationService>().getSelectedDeviceId();
    if (selectedDeviceId != null) {
      final device = BluetoothDeviceManager.pairedDevices.lastWhereOrNull(
        (device) => device.deviceId == selectedDeviceId,
      );
      if (device != null) {
        castingBluetoothDevice = device;
        return device;
      }
    }

    // if no casting device is set, return the first alive device
    final aliveDevice = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
      (device) => device.isAlive,
    );

    if (aliveDevice != null) {
      castingBluetoothDevice = aliveDevice;
      return aliveDevice;
    }

    // if no alive device is found, return first paired device
    final firstPairedDevice = BluetoothDeviceManager.pairedDevices.firstOrNull;
    if (firstPairedDevice != null) {
      castingBluetoothDevice = firstPairedDevice;
      return firstPairedDevice;
    }

    return null;
  }

  Future<FFBluetoothDevice?> pickADeviceToDisplay(String deviceName) async {
    final listDevice = BluetoothDeviceManager.pairedDevices;
    if (listDevice.isEmpty) {
      return null;
    }
    if (listDevice.length == 1) {
      return listDevice.first;
    }

    final device = listDevice.firstWhereOrNull(
      (device) => device.name == deviceName,
    );
    if (device != null) {
      return device;
    }

    final aliveDevices = _castingBluetoothDevice?.isAlive == true
        ? _castingBluetoothDevice!
        : listDevice.firstWhereOrNull(
            (device) => device.isAlive,
          );
    if (aliveDevices != null) {
      return aliveDevices;
    }

    return null;
  }
}
