//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';

class DeviceInfoService {
  late final String _deviceId;
  late final String _deviceName;
  bool _didInitialized = false;

  Future<void> init() async {
    if (_didInitialized) {
      return;
    }
    final device = DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? 'Feral File App';
    _deviceId = await getDeviceID();
    _didInitialized = true;
  }

  String get deviceId => _deviceId;

  String get deviceName => _deviceName;
}
