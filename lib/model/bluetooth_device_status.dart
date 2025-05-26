import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';

class BluetoothDeviceStatus {
  BluetoothDeviceStatus({
    required this.screenRotation,
    this.ipAddress,
    this.connectedWifi,
    this.isConnectedToWifi = false,
    ArtFraming? artFraming,
    this.installedVersion,
    this.latestVersion,
  }) : artFraming = artFraming ?? ArtFraming.fitToScreen;

  factory BluetoothDeviceStatus.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceStatus(
      ipAddress: json['ipAddress'] as String?,
      connectedWifi: json['connectedWifi'] as String?,
      isConnectedToWifi: json['isConnectedToWifi'] as bool? ?? false,
      screenRotation:
          ScreenOrientation.fromString(json['screenRotation'] as String),
      artFraming: json['artFraming'] == null
          ? null
          : ArtFraming.fromValue(json['artFraming'] as int),
      installedVersion: json['installedVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
    );
  }

  // Deprecated
  final String? ipAddress;
  final bool isConnectedToWifi;
  final ArtFraming artFraming;

  final String? connectedWifi;
  final ScreenOrientation screenRotation;
  final String? installedVersion;
  final String? latestVersion;

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'connectedWifi': connectedWifi,
      'screenRotation': screenRotation.name,
      'isConnectedToWifi': isConnectedToWifi,
      'artFraming': artFraming.value,
      'installedVersion': installedVersion,
      'latestVersion': latestVersion,
    };
  }
}
