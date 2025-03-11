import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';

class BluetoothDeviceStatus {
  final String version;
  final String? ipAddress;
  final String? connectedWifi;
  final ScreenOrientation screenRotation;
  final bool isConnectedToWifi;
  final ArtFraming artFraming;
  final String? installedVersion;
  final String? latestVersion;

  BluetoothDeviceStatus({
    required this.version,
    this.ipAddress,
    this.connectedWifi,
    this.isConnectedToWifi = false,
    required this.screenRotation,
    ArtFraming? artFraming,
    this.installedVersion,
    this.latestVersion,
  }) : artFraming = artFraming ?? ArtFraming.fitToScreen;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'ipAddress': ipAddress,
      'connectedWifi': connectedWifi,
      'screenRotation': screenRotation.name,
      'isConnectedToWifi': isConnectedToWifi,
      'artFraming': artFraming.value,
      'installedVersion': installedVersion,
      'latestVersion': latestVersion,
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
      artFraming: json['artFraming'] == null
          ? null
          : ArtFraming.fromValue(json['artFraming'] as int),
      installedVersion: json['installedVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
    );
  }
}
