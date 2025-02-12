import 'package:autonomy_flutter/screen/device_setting/device_config.dart';

class BluetoothDeviceStatus {
  final String version;
  final String? ipAddress;
  final String? connectedWifi;
  final ScreenOrientation screenRotation;
  final bool isConnectedToWifi;

  BluetoothDeviceStatus({
    required this.version,
    this.ipAddress,
    this.connectedWifi,
    this.isConnectedToWifi = false,
    required this.screenRotation,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'ipAddress': ipAddress,
      'connectedWifi': connectedWifi,
      'screenRotation': screenRotation.name,
    };
  }

  factory BluetoothDeviceStatus.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceStatus(
      version: json['version'] as String,
      ipAddress: json['ipAddress'] as String?,
      connectedWifi: json['connectedWifi'] as String?,
      isConnectedToWifi: json['isConnectedToWifi'] as bool? ?? false,
      screenRotation:
          ScreenOrientation.fromString(json['screenRotation'] as String),
    );
  }
}
