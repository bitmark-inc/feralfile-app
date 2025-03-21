import 'dart:async';

import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:objectbox/objectbox.dart';
import 'package:sentry/sentry.dart';

class CanvasDevice implements BaseDevice {
  // device name

  // constructor
  CanvasDevice({
    required this.deviceId,
    required this.locationId,
    required this.topicId,
    required this.name,
  });

  //fromJson method
  factory CanvasDevice.fromJson(Map<String, dynamic> json) => CanvasDevice(
        deviceId: json['deviceId'] as String,
        locationId: json['locationId'] as String,
        topicId: json['topicId'] as String,
        name: json['name'] as String,
      );
  @override
  final String deviceId; //hardware id
  final String locationId; // location id
  final String topicId; // topic id
  @override
  final String name;

  // toJson
  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'locationId': locationId,
        'topicId': topicId,
        'name': name,
      };

  // copyWith
  CanvasDevice copyWith({
    String? deviceId,
    String? locationId,
    String? topicId,
    String? name,
  }) =>
      CanvasDevice(
        deviceId: deviceId ?? this.deviceId,
        locationId: locationId ?? this.locationId,
        topicId: topicId ?? this.topicId,
        name: name ?? this.name,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CanvasDevice && deviceId == other.deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;
}

class DeviceInfo {
  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
  });

  // Factory constructor to create an instance from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String,
      );
  String deviceId;
  String deviceName;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
      };
}

abstract class BaseDevice {
  String get deviceId;

  String get name;
}

@Entity()
class FFBluetoothDevice extends BluetoothDevice implements BaseDevice {
  FFBluetoothDevice({
    required this.name,
    required String remoteID,
  }) : super.fromId(remoteID);

  // fromJson
  factory FFBluetoothDevice.fromJson(Map<String, dynamic> json) =>
      FFBluetoothDevice(
        name: json['name'] as String,
        remoteID: json['remoteID'] as String,
      );

  @Id()
  int objId = 0;

  @override
  final String name;

  String get remoteID => remoteId.str;

  @override
  String get deviceId => remoteId.str;

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'remoteID': remoteID,
      };

  static FFBluetoothDevice fromBluetoothDevice(BluetoothDevice device) {
    final savedDevice = BluetoothDeviceHelper.pairedDevices.firstWhereOrNull(
      (e) => e.remoteID == device.remoteId.str,
    );
    if (savedDevice != null) {
      return savedDevice;
    }
    return FFBluetoothDevice(
      name: device.advName,
      remoteID: device.remoteId.str,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FFBluetoothDevice && remoteID == other.remoteID;
  }

  @override
  int get hashCode => super.hashCode;
}

extension BluetoothDeviceExtension on BluetoothDevice {
  FFBluetoothDevice toFFBluetoothDevice() {
    return FFBluetoothDevice.fromBluetoothDevice(this);
  }

  BluetoothCharacteristic? get commandCharacteristic =>
      BluetoothManager.getCommandCharacteristic(remoteId.str);

  BluetoothCharacteristic? get wifiConnectCharacteristic =>
      BluetoothManager.getWifiConnectCharacteristic(remoteId.str);

  BluetoothCharacteristic? get engineeringCharacteristic =>
      BluetoothManager.getEngineeringCharacteristic(remoteId.str);

  Future<void> discoverCharacteristics() async {
    try {
      log.info('Discovering characteristics for device: ${remoteId.str}');

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
      final commandChar = commandService.characteristics.firstWhere(
          (characteristic) => characteristic.isCommandCharacteristic);
      final wifiConnectChar = commandService.characteristics.firstWhere(
        (characteristic) => characteristic.isWifiConnectCharacteristic,
      );
      final engineeringChar = commandService.characteristics.firstWhere(
        (characteristic) => characteristic.isEngineeringCharacteristic,
      );

      // Set the command and wifi connect characteristics
      BluetoothManager.setCommandCharacteristic(commandChar);
      BluetoothManager.setWifiConnectCharacteristic(wifiConnectChar);
      BluetoothManager.setEngineeringCharacteristic(engineeringChar);

      log.info('Command char properties: ${commandChar.properties}');
      if (!commandChar.properties.notify) {
        log.warning('Command characteristic does not support notifications!');
        unawaited(
          Sentry.captureMessage(
            'Command characteristic does not support notifications',
          ),
        );
        throw Exception(
            'Command characteristic does not support notifications');
      }

      try {
        await commandChar.setNotifyValue(true);
        log.info('Successfully enabled notifications for command char');
      } catch (e) {
        log.warning('Failed to enable notifications for command char: $e');
        unawaited(
            Sentry.captureException('Failed to enable notifications: $e'));
        rethrow;
      }
    } catch (e) {
      log.warning('Error discovering characteristics: $e');
      unawaited(Sentry.captureException(e));
    }
  }
}
