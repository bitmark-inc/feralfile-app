import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';

class DeviceDisplaySetting {
  DeviceDisplaySetting({
    this.scaling,
    this.screenOrientation,
  });

  factory DeviceDisplaySetting.fromJson(Map<String, dynamic> json) {
    return DeviceDisplaySetting(
      scaling: ArtFraming.fromString(json['scaling'] as String),
      screenOrientation:
          ScreenOrientation.fromString(json['orientation'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scaling': scaling?.name,
      'orientation': screenOrientation?.name,
    };
  }

  DeviceDisplaySetting copyWith({
    ArtFraming? scaling,
    ScreenOrientation? screenOrientation,
  }) {
    return DeviceDisplaySetting(
      scaling: scaling ?? this.scaling,
      screenOrientation: screenOrientation ?? this.screenOrientation,
    );
  }

  ArtFraming? scaling;
  ScreenOrientation? screenOrientation;
}
