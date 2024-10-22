//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

String? _cacheDeviceId;

Future<String> getDeviceID() async {
  if (_cacheDeviceId != null) {
    return _cacheDeviceId!;
  }
  String deviceId = '';
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    deviceId = iosDeviceInfo.identifierForVendor ??
        const Uuid().v4(); // unique ID on iOS
  } else {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    deviceId = androidDeviceInfo.id; // unique ID on Android
  }
  _cacheDeviceId = deviceId;
  return _cacheDeviceId!;
}
