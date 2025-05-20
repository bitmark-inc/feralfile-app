import 'dart:async';

import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:objectbox/objectbox.dart';
import 'package:sentry/sentry.dart';

abstract class BaseDevice {
  const BaseDevice({
    required this.locationId,
    required this.topicId,
  });

  String get deviceId;

  String get name;

  final String locationId;

  final String topicId;
}

@Entity()
class FFBluetoothDevice extends BluetoothDevice implements BaseDevice {
  FFBluetoothDevice({
    required this.name,
    required String remoteID,
    required this.locationId,
    required this.topicId,
  }) : super.fromId(remoteID);

  // fromJson
  factory FFBluetoothDevice.fromJson(Map<String, dynamic> json) =>
      FFBluetoothDevice(
        name: json['name'] as String,
        remoteID: json['remoteID'] as String,
        locationId: json['locationId'] as String,
        topicId: json['topicId'] as String,
      );

  @Id()
  int objId = 0;

  @override
  final String name;

  String get remoteID => remoteId.str;

  @override
  String get deviceId => remoteId.str;

  @override
  final String locationId; // location id
  @override
  final String topicId; // topic id

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'remoteID': remoteID,
        'locationId': locationId,
        'topicId': topicId,
      };

  static FFBluetoothDevice fromBluetoothDevice(BluetoothDevice device,
      {String? locationId, String? topicId}) {
    final savedDevice = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
      (e) => e.remoteID == device.remoteId.str,
    );
    return FFBluetoothDevice(
      name: device.getName,
      remoteID: device.remoteId.str,
      locationId: locationId ?? savedDevice?.locationId ?? '',
      topicId: topicId ?? savedDevice?.topicId ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FFBluetoothDevice &&
        other.remoteID == remoteID &&
        other.locationId == locationId &&
        other.topicId == topicId;
  }

  @override
  int get hashCode => super.hashCode;
}

extension BluetoothDeviceExtension on BluetoothDevice {
  FFBluetoothDevice toFFBluetoothDevice({String? locationId, String? topicId}) {
    return FFBluetoothDevice.fromBluetoothDevice(this,
        locationId: locationId, topicId: topicId);
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
      await Future.delayed(const Duration(seconds: 1));
      final discoveredServices = await discoverServices();
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
