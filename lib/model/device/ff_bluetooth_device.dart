import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
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
  }) : super.fromId(remoteID);

  factory FFBluetoothDevice.fromBluetoothDevice(BluetoothDevice device,
      {String? topicId}) {
    final savedDevice = BluetoothDeviceManager.pairedDevices.firstWhereOrNull(
      (e) => e.remoteID == device.remoteId.str,
    );
    return FFBluetoothDevice(
      name: device.getName,
      remoteID: device.remoteId.str,
      topicId: topicId ?? savedDevice?.topicId ?? '',
    );
  }

  // fromJson
  factory FFBluetoothDevice.fromJson(Map<String, dynamic> json) =>
      FFBluetoothDevice(
        name: json['name'] as String,
        remoteID: json['remoteID'] as String,
        topicId: json['topicId'] as String,
      );

  @override
  final String name;

  String get remoteID => remoteId.str;

  @override
  String get deviceId => remoteId.str;

  @override
  final String topicId; // topic id

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'remoteID': remoteID,
        'topicId': topicId,
      };

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
  String get key => name;

  @override
  Map<String, String> get toKeyValue => {
        'key': key,
        'value': value,
      };

  @override
  String get value => jsonEncode(toJson());
}
