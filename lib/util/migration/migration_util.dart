//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:flutter/services.dart';

class MigrationUtil {
  static const MethodChannel _channel = MethodChannel('migration_util');
  final AccountService _accountService;
  final int requiredAndroidMigrationVersion = 95;

  MigrationUtil(this._accountService);

  Future<void> migrationFromKeychain() async {
    if (!Platform.isIOS) {
      return;
    }
    final keychainUUIDs =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});
    final List<String> personaUUIDs =
        keychainUUIDs.map((e) => e.toString().toLowerCase()).tolist();
    await _accountService.restoreUUIDs(personaUUIDs);
  }

  static Future<String?> getBackupDeviceID() async {
    if (Platform.isIOS) {
      final String? deviceId = await _channel.invokeMethod('getDeviceID', {});

      return deviceId ?? await getDeviceID();
    } else {
      return await getDeviceID();
    }
  }
}
