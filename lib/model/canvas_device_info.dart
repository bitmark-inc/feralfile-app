import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:objectbox/objectbox.dart';

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

  // fromJson
  factory FFBluetoothDevice.fromJson(Map<String, dynamic> json) =>
      FFBluetoothDevice(
        name: json['name'] as String,
        remoteID: json['remoteID'] as String,
      );

  static FFBluetoothDevice fromBluetoothDevice(BluetoothDevice device) {
    return FFBluetoothDevice(name: device.name, remoteID: device.remoteId.str);
  }
}
