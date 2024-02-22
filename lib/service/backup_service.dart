//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/sqlite_cloud_database.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/backup_versions.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:floor/floor.dart';
import 'package:http/http.dart' as http;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const _dbFileName = 'cloud_database.db';
  static const _dbEncryptedFileName = 'cloud_database.db.encrypted';

  final IAPApi _iapApi;
  final CloudFirestoreService _cloudFirestoreService;

  BackupService(this._iapApi, this._cloudFirestoreService);

  Future deleteAllProfiles(WalletStorage account) async {
    log.info('[BackupService][start] deleteAllProfiles');
    String? deviceId = await getBackupId();
    final endpoint = Environment.autonomyAuthURL;
    final authToken = await getAuthToken(account);

    await http.delete(Uri.parse('$endpoint/apis/v1/premium/profile-data'),
        headers: {'requester': deviceId, 'Authorization': 'Bearer $authToken'});
  }

  Future<String> fetchBackupVersion(WalletStorage account) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    String? deviceId = await getBackupId();
    final authToken = await getAuthToken(account);

    final endpoint = Environment.autonomyAuthURL;

    http.Response? response;

    for (String filename in [_dbEncryptedFileName, _dbFileName]) {
      try {
        response = await http.get(
            Uri.parse(
                '$endpoint/apis/v1/premium/profile-data/versions?filename=$filename'),
            headers: {
              'requester': deviceId,
              'Authorization': 'Bearer $authToken'
            });
        if (response.statusCode == 200) {
          break;
        }
      } catch (e) {
        log.warning('[BackupService] failed fetch $filename $e');
      }
    }

    if (response == null || response.statusCode != 200) {
      log.warning('[BackupService] failed fetchBackupVersion');
      throw FailedFetchBackupVersion();
    }

    final result = BackupVersions.fromJson(json.decode(response.body));

    var versions = result.versions..sort((a, b) => compareVersion(b, a));

    String backupVersion = '';
    for (String element in versions) {
      if (compareVersion(element, version) <= 0) {
        backupVersion = element;
        break;
      }
    }

    return backupVersion;
  }

  Future<bool> restoreCloudDatabaseIfNeed(WalletStorage account, String version,
      {String dbName = 'cloud_database.db'}) async {
    log.info('[BackupService] start database restore');
    final alreadyBackupSqliteDatabase =
        await _cloudFirestoreService.isAlreadyBackupFromSqlite();
    if (alreadyBackupSqliteDatabase) {
      log.info('[BackupService] already backup from sqlite database');
      return false;
    }

    String? deviceId = await getBackupId();
    final authToken = await getAuthToken(account);

    final endpoint = Environment.autonomyAuthURL;
    final resp = await http.get(
      Uri.parse(
          '$endpoint/apis/v1/premium/profile-data?filename=$_dbEncryptedFileName&appVersion=$version'),
      headers: {
        'requester': deviceId,
        'Authorization': 'Bearer $authToken',
      },
    );
    if (resp.statusCode == 200) {
      try {
        final tempFilePath =
            '${(await getTemporaryDirectory()).path}/$_dbEncryptedFileName';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(resp.bodyBytes, flush: true);
        const String tempDbName = 'temp_cloud_database.db';
        final dbFilePath =
            await sqfliteDatabaseFactory.getDatabasePath(tempDbName);
        await account.decryptFile(
          inputPath: tempFilePath,
          outputPath: dbFilePath,
        );
        final tempDb =
            await $FloorSqliteCloudDatabase.databaseBuilder(tempDbName).build();
        await injector<SqliteCloudDatabase>().copyDataFrom(tempDb);
        await tempFile.delete();
        await File(dbFilePath).delete();
        await _cloudFirestoreService.backupCloudDatabase(
            sqliteCloudDatabase: injector<SqliteCloudDatabase>());
      } catch (e) {
        log.info('[BackupService] Failed to restore Cloud Database $e');
        return true;
      }
    }
    injector<MetricClientService>().onRestore();
    await _cloudFirestoreService.setAlreadyBackupFromSqlite();
    log.info('[BackupService] done database restore');
    return true;
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await MigrationUtil.getBackupDeviceID();

    return '${deviceId}_${packageInfo.packageName}';
  }

  Future<String> getAuthToken(WalletStorage account) async {
    final message = DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      'requester': accountDID,
      'timestamp': message,
      'signature': signature,
    };

    final jwt = await _iapApi.auth(payload);
    return jwt.jwtToken;
  }
}
