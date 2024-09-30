//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  String _deviceId = '';
  String _deviceName = '';
  bool _didInitialized = false;

  // If the device name and id are not available, set default values
  // Errors can be ignored when opening the app
  Future<void> init() async {
    if (_didInitialized) {
      return;
    }
    // Get device name and id
    try {
      final device = DeviceInfo.instance;
      _deviceName = await device.getMachineName() ?? 'Feral File App';
      _deviceId = await getDeviceID();
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
  }

  String get deviceId => _deviceId;

  String get deviceName => _deviceName;
}
