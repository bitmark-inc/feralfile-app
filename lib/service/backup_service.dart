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
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/backup_versions.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:floor/floor.dart';
import 'package:http/http.dart' as http;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const _dbFileName = 'cloud_database.db';
  static const _dbEncryptedFileName = 'cloud_database.db.encrypted';

  final CloudManager _cloudObjects;

  BackupService(this._cloudObjects);

  Future<String> getBackupVersion(String deviceId) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    final authToken = await injector<AuthService>().getAuthToken();

    if (authToken == null) {
      return '';
    }

    final endpoint = Environment.autonomyAuthURL;

    http.Response? response;

    for (String filename in [_dbEncryptedFileName, _dbFileName]) {
      try {
        response = await http.get(
            Uri.parse(
                '$endpoint/apis/v1/premium/profile-data/versions?filename=$filename'),
            headers: {
              'requester': deviceId,
              'Authorization': 'Bearer ${authToken.jwtToken}'
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
      return '';
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
    final authToken = await injector<AuthService>().getAuthToken();

    await http.delete(Uri.parse('$endpoint/apis/v1/premium/profile-data'),
        headers: {
          'requester': deviceId,
          'Authorization': 'Bearer ${authToken?.jwtToken}'
        });
  }

  Future restoreCloudDatabase({String dbName = 'cloud_database.db'}) async {
    log.info('[BackupService] start database restore');

    String? deviceId = await getBackupId();
    final version = await getBackupVersion(deviceId);
    final authToken = await injector<AuthService>().getAuthToken();
    final primaryAddressInfo =
        await injector<AddressService>().getPrimaryAddressInfo();
    final account = LibAukDart.getWallet(primaryAddressInfo!.uuid);
    final endpoint = Environment.autonomyAuthURL;
    final resp = await http.get(
      Uri.parse(
          '$endpoint/apis/v1/premium/profile-data?filename=$_dbEncryptedFileName&appVersion=$version'),
      headers: {
        'requester': deviceId,
        'Authorization': 'Bearer ${authToken?.jwtToken}',
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
          unawaited(Sentry.captureException(
              '[BackupService] Cloud database decrypted failed, '
              'fallback to legacy method, $e'));
          await account.decryptFile(
            inputPath: tempFilePath,
            outputPath: dbFilePath,
            usingLegacy: true,
          );
        }

        final tempDb =
            await $FloorCloudDatabase.databaseBuilder(tempDbName).build();
        await _cloudObjects.copyDataFrom(tempDb);
        await tempFile.delete();
        await File(dbFilePath).delete();
        log.info('[BackupService] Cloud database is restored $version');
        return;
      } catch (e) {
        log.info('[BackupService] Failed to restore Cloud Database $e');
        unawaited(Sentry.captureException(e, stackTrace: StackTrace.current));
      }
    }
    await _cloudObjects.setMigrated();

    log.info('[BackupService] done database restore');
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await injector<AccountService>().getBackupDeviceID();

    return '${deviceId}_${packageInfo.packageName}';
  }
}
