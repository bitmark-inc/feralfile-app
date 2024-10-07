//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';

class AndroidBackupChannel {
  static const MethodChannel _channel = MethodChannel('backup');

  Future<bool?> isEndToEndEncryptionAvailable() async =>
      await _channel.invokeMethod('isEndToEndEncryptionAvailable', {});

  Future backupKeys(List<String> uuids) async {
    try {
      await _channel.invokeMethod('backupKeys', {'uuids': uuids});
    } catch (e) {
      log.warning('Android cloud backup error', e);
    }
  }

  Future<List<BackupAccount>> restoreKeys() async {
    try {
      String data = await _channel.invokeMethod('restoreKeys', {});
      if (data.isEmpty) {
        return [];
      }
      final backupData = json.decode(data);
      final accounts = BackupData.fromJson(backupData).accounts;
      return accounts;
    } catch (e) {
      log.warning('Android cloud backup error', e);
      return [];
    }
  }

  Future deleteBlockStoreData() async {
    try {
      await _channel.invokeMethod('deleteKeys', {});
    } catch (e) {
      log.warning('Android cloud backup error', e);
    }
  }
}

class BackupData {
  BackupData({
    required this.accounts,
  });

  List<BackupAccount> accounts;

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
        accounts: List<BackupAccount>.from(
            json['accounts'].map((x) => BackupAccount.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        'accounts': accounts,
      };
}

class BackupAccount {
  BackupAccount({
    required this.uuid,
    required this.name,
  });

  String uuid;
  String name;

  factory BackupAccount.fromJson(Map<String, dynamic> json) => BackupAccount(
        uuid: json['uuid'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
      };
}
