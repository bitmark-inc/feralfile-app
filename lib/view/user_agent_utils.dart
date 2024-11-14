//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

enum DeviceType { phone, tablet, desktop }

class DeviceInfo {
  DeviceInfo._();

  static final IDeviceInfo _instance = _MobileInfo();

  static IDeviceInfo get instance => _instance;
}

abstract class IDeviceInfo {
  abstract final bool isPhone;
  abstract final bool isTablet;
  abstract final bool isDesktop;
  abstract final bool isAndroid;
  abstract final bool isIOS;

  Future<void> init();

  Future<String?> getMachineName();

  Future<UserDeviceInfo> getUserDeviceInfo();
}

class _MobileInfo extends IDeviceInfo {
  bool _isTablet = false;

  @override
  bool get isPhone => !_isTablet;

  @override
  bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  bool get isTablet => _isTablet;

  @override
  Future<void> init() async {
    log.info('[DeviceInfo] init');
    _isTablet = await _checkIsTablet();
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String?> _getMachineName() async {
    if (isIOS) {
      return (await _deviceInfo.iosInfo).utsname.machine;
    }
    if (isAndroid) {
      return (await _deviceInfo.androidInfo).model;
    }
    return null;
  }

  @override
  Future<String?> getMachineName() async {
    try {
      return await _getMachineName();
    } catch (e) {
      unawaited(Sentry.captureException(e));
      return null;
    }
  }

  Future<bool> _checkIsTablet() async {
    if (isIOS) {
      final info = await _deviceInfo.iosInfo;
      final machine = info.utsname.machine.toLowerCase();
      final model = info.model.toLowerCase();
      return machine.contains('ipad') || model.contains('ipad');
    }
    if (isAndroid) {
      final data = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.single);
      return data.size.shortestSide > 600;
    }

    return false;
  }

  Future<int> getAndroidSdkInt() async {
    if (isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } else {
      return -1;
    }
  }

  @override
  Future<UserDeviceInfo> getUserDeviceInfo() async {
    if (isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final model = androidInfo.model;
      final vendor = androidInfo.manufacturer;
      final name = '$vendor ${androidInfo.brand} $model';
      const osName = 'Android';
      final osVersion = androidInfo.version.release;
      return UserDeviceInfo(name, model, vendor, osName, osVersion);
    } else {
      final iOSInfo = await _deviceInfo.iosInfo;
      final model = iOSInfo.utsname.machine;
      const vendor = 'Apple';
      final name = '$vendor $model';
      const osName = 'iOS';
      final osVersion = iOSInfo.systemVersion;
      return UserDeviceInfo(name, model, vendor, osName, osVersion);
    }
  }
}

class UserDeviceInfo {
  final String name;
  final String model;
  final String vendor;
  final String osName;
  final String oSVersion;

  UserDeviceInfo(this.name, this.model, this.vendor, this.osName,
      this.oSVersion);
}
