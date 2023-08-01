//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

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

  Future<bool> isSupportOS();
}

class _MobileInfo extends IDeviceInfo {
  late bool _isTablet;

  @override
  bool get isPhone => !_isTablet;

  @override
  bool get isDesktop =>
      (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  bool get isTablet => _isTablet;

  @override
  Future<void> init() async {
    _isTablet = await _checkIsTablet();
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  Future<String?> getMachineName() async {
    if (isIOS) {
      return (await _deviceInfo.iosInfo).utsname.machine;
    }
    if (isAndroid) {
      return (await _deviceInfo.androidInfo).model;
    }
    return null;
  }

  Future<bool> _checkIsTablet() async {
    if (isIOS) {
      final info = await _deviceInfo.iosInfo;
      final machine = info.utsname.machine!.toLowerCase();
      final model = info.model!.toLowerCase();
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
  Future<bool> isSupportOS() async {
    if (isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final version = androidInfo.version.release;
      return version.isEmpty || int.parse(version.split(".")[0]) > 8;
    } else {
      final iOSInfo = await _deviceInfo.iosInfo;
      final version = iOSInfo.systemVersion;
      return version == null || int.parse(version.split(".")[0]) > 14;
    }
  }
}
