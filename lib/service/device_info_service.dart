//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  String _deviceId = '';
  String _deviceName = '';
  String _deviceModel = '';
  String _deviceVendor = '';
  String _deviceOSName = '';
  String _deviceOSVersion = '';
  bool _didInitialized = false;
  Map<String, String> _appleModelIdentifier = {};

  // If the device name and id are not available, set default values
  // Errors can be ignored when opening the app
  Future<void> init() async {
    log.info('[DeviceInfoService] init');
    if (_didInitialized) {
      log.info('[DeviceInfoService] already initialized');
      return;
    }
    // Get device name, id and OS information
    try {
      final device = DeviceInfo.instance;
      _deviceId = await getDeviceID();
      final deviceInfo = await device.getUserDeviceInfo();
      _deviceName = deviceInfo.name;
      _deviceModel = deviceInfo.model;
      _deviceVendor = deviceInfo.vendor;
      _deviceOSName = deviceInfo.osName;
      _deviceOSVersion = deviceInfo.oSVersion;
      await getAppleModelIdentifier();
    } catch (e) {
      // if failed to get device name and id, set default values
      if (_deviceName.isEmpty) {
        _deviceName = 'Feral File App';
      }
      if (_deviceId.isEmpty) {
        _deviceId = const Uuid().v4();
      }
    }

    // set didInitialized to true
    _didInitialized = true;
    log.info('[DeviceInfoService] initialized');
  }

  Future<Map<String, String>> getAppleModelIdentifier() async {
    if (_appleModelIdentifier.isNotEmpty) {
      return _appleModelIdentifier;
    }
    final res = await injector<PubdocAPI>().getAppleModelIdentifier();
    final json = jsonDecode(res) as Map<String, dynamic>;
    _appleModelIdentifier =
        json.map((key, value) => MapEntry(key, value.toString()));
    return _appleModelIdentifier;
  }

  String get deviceId => _deviceId;

  String get deviceName {
    if (Platform.isAndroid) {
      return '$_deviceVendor $_deviceModel';
    } else {
      return _mapIphoneIdentifierToModel(_deviceModel);
    }
  }

  String get deviceModel => _deviceModel;

  String get deviceVendor => _deviceVendor;

  // OS related information
  String get deviceOSName => _deviceOSName;

  String get deviceOSVersion => _deviceOSVersion;

  String _mapIphoneIdentifierToModel(String identifier) {
    if (_appleModelIdentifier.isEmpty) {
      return iphoneIdentifierCache[identifier] ?? identifier;
    } else {
      return _appleModelIdentifier[identifier] ?? identifier;
    }
  }
}

const iphoneIdentifierCache = {
  'iPhone1,1': 'iPhone',
  'iPhone1,2': 'iPhone3G',
  'iPhone2,1': 'iPhone3GS',
  'iPhone3,1': 'iPhone4',
  'iPhone3,2': 'iPhone4',
  'iPhone3,3': 'iPhone4',
  'iPhone4,1': 'iPhone4S',
  'iPhone5,1': 'iPhone5',
  'iPhone5,2': 'iPhone5',
  'iPhone5,3': 'iPhone5c',
  'iPhone5,4': 'iPhone5c',
  'iPhone6,1': 'iPhone5s',
  'iPhone6,2': 'iPhone5s',
  'iPhone7,2': 'iPhone6',
  'iPhone7,1': 'iPhone6Plus',
  'iPhone8,1': 'iPhone6s',
  'iPhone8,2': 'iPhone6sPlus',
  'iPhone8,4': 'iPhoneSE',
  'iPhone9,1': 'iPhone7',
  'iPhone9,2': 'iPhone7Plus',
  'iPhone9,3': 'iPhone7',
  'iPhone9,4': 'iPhone7Plus',
  'iPhone10,1': 'iPhone8',
  'iPhone10,2': 'iPhone8Plus',
  'iPhone10,3': 'iPhoneX',
  'iPhone10,4': 'iPhone8',
  'iPhone10,5': 'iPhone8Plus',
  'iPhone10,6': 'iPhoneX',
  'iPhone11,2': 'iPhoneXS',
  'iPhone11,4': 'iPhoneXSMax',
  'iPhone11,6': 'iPhoneXSMax',
  'iPhone11,8': 'iPhoneXR',
  'iPhone12,1': 'iPhone11',
  'iPhone12,3': 'iPhone11Pro',
  'iPhone12,5': 'iPhone11ProMax',
  'iPhone12,8': 'iPhoneSE',
  'iPhone13,1': 'iPhone12mini',
  'iPhone13,2': 'iPhone12',
  'iPhone13,3': 'iPhone12Pro',
  'iPhone13,4': 'iPhone12ProMax',
  'iPhone14,2': 'iPhone13Pro',
  'iPhone14,3': 'iPhone13ProMax',
  'iPhone14,4': 'iPhone13mini',
  'iPhone14,5': 'iPhone13',
  'iPhone14,6': 'iPhoneSE',
  'iPhone15,2': 'iPhone14Pro',
  'iPhone15,3': 'iPhone14Pro Max',
  'iPhone15,4': 'iPhone14',
  'iPhone15,5': 'iPhone14Plus',
  'iPhone16,1': 'iPhone15',
  'iPhone16,2': 'iPhone15Pro',
  'iPhone16,3': 'iPhone15Plus',
  'iPhone16,4': 'iPhone15ProMax',
  'iPhone17,1': 'iPhone16Pro',
  'iPhone17,2': 'iPhone16Pro Max',
  'iPhone17,3': 'iPhone16',
  'iPhone17,4': 'iPhone16Plus',
  'iPhone17,5': 'iPhone16e'
};
