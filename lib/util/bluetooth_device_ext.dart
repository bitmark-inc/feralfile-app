import 'dart:async';

import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry.dart';

extension BluetoothDeviceExtension on BluetoothDevice {
  FFBluetoothDevice toFFBluetoothDevice(
      {String? topicId,
      required String deviceId,
      required DeviceReleaseBranch branchName}) {
    return FFBluetoothDevice.fromBluetoothDevice(this,
        topicId: topicId, deviceId: deviceId, branchName: branchName);
  }

  BluetoothCharacteristic? get wifiConnectCharacteristic =>
      BluetoothManager.getWifiConnectCharacteristic(remoteId.str);

  String get getName {
    final savedName = BluetoothDeviceManager.pairedDevices
        .firstWhereOrNull(
          (e) => e.remoteID == remoteId.str,
        )
        ?.name;
    if (savedName != null) {
      return savedName;
    }

    final name = advName;
    if (name.isNotEmpty) {
      return name;
    }
    return 'FF-X1';
  }

  Future<void> discoverCharacteristics() async {
    try {
      log.info('Discovering characteristics for device: ${remoteId.str}');
      await Future<void>.delayed(const Duration(seconds: 1));
      final discoveredServices = await discoverServices(timeout: 30);
      final services = <BluetoothService>[]
        ..clear()
        ..addAll(discoveredServices);

      final primaryService = services.firstWhereOrNull(
        (service) => service.isPrimary,
      );

      if (primaryService == null) {
        log.warning('Primary service not found');
        unawaited(Sentry.captureMessage('Primary service not found'));
        return;
      } else {
        log.info('Primary service found: ${primaryService.uuid}');
      }

      // if the command and wifi connect characteristics are not found, try to find them
      final commandService = services.firstWhereOrNull(
        (service) => service.uuid.toString() == BluetoothManager.serviceUuid,
      );

      if (commandService == null) {
        unawaited(Sentry.captureMessage('Command service not found'));
        return;
      }
      final wifiConnectChar = commandService.characteristics.firstWhere(
        (characteristic) => characteristic.isWifiConnectCharacteristic,
      );

      // Set the command and wifi connect characteristics
      BluetoothManager.setWifiConnectCharacteristic(wifiConnectChar);

      if (!wifiConnectChar.properties.notify) {
        log.warning('Command characteristic does not support notifications!');
        unawaited(
          Sentry.captureMessage(
            'Command characteristic does not support notifications',
          ),
        );
        throw Exception(
          'Command characteristic does not support notifications',
        );
      }

      try {
        await wifiConnectChar.setNotifyValue(true);
        log.info('Successfully enabled notifications for command char');
      } catch (e) {
        log.warning('Failed to enable notifications for command char: $e');
        unawaited(
          Sentry.captureException('Failed to enable notifications: $e'),
        );
        rethrow;
      }
    } catch (e) {
      log.warning('Error discovering characteristics: $e');
      unawaited(Sentry.captureException(e));
    }
  }
}
