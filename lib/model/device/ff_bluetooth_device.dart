import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/bluetooth_device_ext.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FFBluetoothDevice extends BluetoothDevice
    implements BaseDevice, SettingObject {
  FFBluetoothDevice({
    required this.name,
    required String remoteID,
    required this.topicId,
    required this.deviceId,
  }) : super.fromId(remoteID);

  factory FFBluetoothDevice.fromBluetoothDevice(BluetoothDevice device,
      {String? topicId, required String deviceId}) {
    final savedDevice = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
      (e) => e.remoteID == device.remoteId.str,
    );
    return FFBluetoothDevice(
      name: device.getName,
      remoteID: device.remoteId.str,
      topicId: topicId ?? savedDevice?.topicId ?? '',
      deviceId: deviceId,
    );
  }

  // fromJson
  factory FFBluetoothDevice.fromJson(Map<String, dynamic> json) =>
      FFBluetoothDevice(
        name: json['name'] as String,
        remoteID: json['remoteID'] as String,
        topicId: json['topicId'] as String,
        deviceId: json['deviceId'] != null
            ? json['deviceId'] as String
            : json['name'] as String, // TODO: remove this fallback
      );

  @override
  final String name;

  String get remoteID => remoteId.str;

  @override
  final String topicId; // topic id

  @override
  final String deviceId; // device id

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'remoteID': remoteID,
        'topicId': topicId,
        'deviceId': deviceId,
      };

  // copyWith
  FFBluetoothDevice copyWith({
    String? name,
    String? remoteID,
    String? topicId,
    String? deviceId,
  }) {
    return FFBluetoothDevice(
      name: name ?? this.name,
      remoteID: remoteID ?? this.remoteID,
      topicId: topicId ?? this.topicId,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FFBluetoothDevice &&
        other.remoteID == remoteID &&
        other.topicId == topicId;
  }

  @override
  int get hashCode => super.hashCode;

  @override
  String get key => deviceId;

  @override
  Map<String, String> get toKeyValue => {
        'key': key,
        'value': value,
      };

  @override
  String get value => jsonEncode(toJson());
}

extension FFBluetoothDeviceExt on FFBluetoothDevice {
  bool get isAlive {
    final state = injector<CanvasDeviceBloc>().state;
    return state.isDeviceAlive(this);
  }
}
