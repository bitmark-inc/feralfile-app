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
      return _deviceVendor + ' ' + _deviceModel;
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
  'iPhone1,2': 'iPhone 3G',
  'iPhone2,1': 'iPhone 3GS',
  'iPhone3,1': 'iPhone 4',
  'iPhone3,2': 'iPhone 4',
  'iPhone3,3': 'iPhone 4',
  'iPhone4,1': 'iPhone 4S',
  'iPhone5,1': 'iPhone 5',
  'iPhone5,2': 'iPhone 5',
  'iPhone5,3': 'iPhone 5c',
  'iPhone5,4': 'iPhone 5c',
  'iPhone6,1': 'iPhone 5s',
  'iPhone6,2': 'iPhone 5s',
  'iPhone7,2': 'iPhone 6',
  'iPhone7,1': 'iPhone 6 Plus',
  'iPhone8,1': 'iPhone 6s',
  'iPhone8,2': 'iPhone 6s Plus',
  'iPhone8,4': 'iPhone SE',
  'iPhone9,1': 'iPhone 7',
  'iPhone9,2': 'iPhone 7 Plus',
  'iPhone9,3': 'iPhone 7',
  'iPhone9,4': 'iPhone 7 Plus',
  'iPhone10,1': 'iPhone 8',
  'iPhone10,2': 'iPhone 8 Plus',
  'iPhone10,3': 'iPhone X',
  'iPhone10,4': 'iPhone 8',
  'iPhone10,5': 'iPhone 8 Plus',
  'iPhone10,6': 'iPhone X',
  'iPhone11,2': 'iPhone XS',
  'iPhone11,4': 'iPhone XS Max',
  'iPhone11,6': 'iPhone XS Max',
  'iPhone11,8': 'iPhone XR',
  'iPhone12,1': 'iPhone 11',
  'iPhone12,3': 'iPhone 11 Pro',
  'iPhone12,5': 'iPhone 11 Pro Max',
  'iPhone12,8': 'iPhone SE',
  'iPhone13,1': 'iPhone 12 mini',
  'iPhone13,2': 'iPhone 12',
  'iPhone13,3': 'iPhone 12 Pro',
  'iPhone13,4': 'iPhone 12 Pro Max',
  'iPhone14,2': 'iPhone 13 Pro',
  'iPhone14,3': 'iPhone 13 Pro Max',
  'iPhone14,4': 'iPhone 13 mini',
  'iPhone14,5': 'iPhone 13',
  'iPhone14,6': 'iPhone SE',
  'iPhone15,2': 'iPhone 14 Pro',
  'iPhone15,3': 'iPhone 14 Pro Max',
  'iPhone15,4': 'iPhone 14',
  'iPhone15,5': 'iPhone 14 Plus',
  'iPhone16,1': 'iPhone 15',
  'iPhone16,2': 'iPhone 15 Pro',
  'iPhone16,3': 'iPhone 15 Plus',
  'iPhone16,4': 'iPhone 15 Pro Max',
  'iPhone17,1': 'iPhone 16 Pro',
  'iPhone17,2': 'iPhone 16 Pro Max',
  'iPhone17,3': 'iPhone 16',
  'iPhone17,4': 'iPhone 16 Plus',
  'iPhone17,5': 'iPhone 16e'
};
