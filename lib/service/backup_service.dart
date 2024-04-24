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
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/backup_versions.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:floor/floor.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry/sentry.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const _dbFileName = 'cloud_database.db';
  static const _dbEncryptedFileName = 'cloud_database.db.encrypted';

  final IAPApi _iapApi;

  BackupService(this._iapApi);

  Future backupCloudDatabase(WalletStorage account) async {
    log.info('[BackupService] start database backup');
    try {
      final path = await sqfliteDatabaseFactory.getDatabasePath(_dbFileName);
      String tempDir = (await getTemporaryDirectory()).path;
      final encryptedFilePath = await account.encryptFile(
        inputPath: path,
        outputPath: '$tempDir/$_dbEncryptedFileName',
      );
      final file = File(encryptedFilePath);

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String? deviceId = await getBackupId();

      await _iapApi.uploadProfile(
          deviceId, _dbEncryptedFileName, version, file);
      await file.delete();
    } catch (err) {
      debugPrint('[BackupService] error database backup, $err');
    }

    log.info('[BackupService] done database backup');
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

  Future deleteAllProfiles(WalletStorage account) async {
    log.info('[BackupService][start] deleteAllProfiles');
    String? deviceId = await getBackupId();
    final endpoint = Environment.autonomyAuthURL;
    final authToken = await getAuthToken(account);

    await http.delete(Uri.parse('$endpoint/apis/v1/premium/profile-data'),
        headers: {'requester': deviceId, 'Authorization': 'Bearer $authToken'});
  }

  Future restoreCloudDatabase(WalletStorage account, String version,
      {String dbName = 'cloud_database.db'}) async {
    log.info('[BackupService] start database restore');
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
      log.info('[BackupService] got response');
      try {
        final version = await injector<CloudDatabase>().database.getVersion();
        log.info('[BackupService] Cloud database local version is $version');
        final tempFilePath =
            '${(await getTemporaryDirectory()).path}/$_dbEncryptedFileName';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(resp.bodyBytes, flush: true);
        const String tempDbName = 'temp_cloud_database.db';
        final dbFilePath =
            await sqfliteDatabaseFactory.getDatabasePath(tempDbName);

        try {
          await account.decryptFile(
            inputPath: tempFilePath,
            outputPath: dbFilePath,
          );
        } catch (e) {
          log.warning('[BackupService] Cloud database decrypted failed,'
              ' fallback to legacy method');
          await account.decryptFile(
            inputPath: tempFilePath,
            outputPath: dbFilePath,
            usingLegacy: true,
          );
        }

        final tempDbOld = await sqfliteDatabaseFactory.openDatabase(dbFilePath);
        final backUpVersion = await tempDbOld.getVersion();
        log.info(
            '[BackupService] Cloud database backup version is $backUpVersion');
        if (version > backUpVersion) {
          await MigrationAdapter.runMigrations(
              tempDbOld, backUpVersion, version, cloudDatabaseMigrations);
        }

        final tempDb =
            await $FloorCloudDatabase.databaseBuilder(tempDbName).build();
        await injector<CloudDatabase>().copyDataFrom(tempDb);
        await tempFile.delete();
        await File(dbFilePath).delete();
        log.info(
            '[BackupService] Cloud database is restored $backUpVersion to '
                '$version');
        return;
      } catch (e) {
        log.info("[BackupService] Failed to restore Cloud Database $e");
        unawaited(Sentry.captureException(e, stackTrace: StackTrace.current));
        return;
      }
    }
    log.info('[BackupService] done database restore');
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
