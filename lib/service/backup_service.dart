import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:floor/floor.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class BackupService {
  final IAPApi _iapApi;
  final ConfigurationService _configurationService;

  BackupService(this._iapApi, this._configurationService);

  Future backupCloudDatabase() async {
    log.info("[BackupService] start database backup");
    final filename = 'cloud_database.db';

    try {
      final path = await sqfliteDatabaseFactory.getDatabasePath(filename);
      final file = File(path);

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String? deviceId = await getBackupId();

      await _iapApi.uploadProfile(deviceId, filename, version, file);
    } catch (err) {
      print(err);
      log.warning("[BackupService] error database backup");
    }

    log.info("[BackupService] done database backup");
  }

  Future<String> fetchBackupVersion() async {
    final filename = 'cloud_database.db';

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    String? deviceId = await getBackupId();

    final result = await _iapApi.getProfileVersions(deviceId, filename);

    var versions = result.versions..sort((a, b) => compareVersion(b, a));

    String backupVersion = "";
    for (String element in versions) {
      if (compareVersion(element, version) <= 0) {
        backupVersion = element;
        break;
      }
    }

    return backupVersion;
  }

  Future deleteAllProfiles() async {
    log.info("[BackupService][start] deleteAllProfiles");

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await getBackupId();

    await _iapApi.deleteAllProfiles(deviceId);
  }

  Future restoreCloudDatabase(String version) async {
    log.info("[BackupService] start database restore");
    final filename = 'cloud_database.db';

    String? deviceId = await getBackupId();

    final endpoint = Environment.autonomyAuthURL;
    final response = await http.get(
        Uri.parse(
            "$endpoint/apis/v1/premium/profile-data?filename=$filename&appVersion=$version"),
        headers: {"requester": deviceId});

    if (response.contentLength == 0 && response.statusCode != 200) {
      log.warning("[BackupService] failed database restore");
      return;
    }

    final path = await sqfliteDatabaseFactory.getDatabasePath(filename);
    final file = File(path);

    await file.writeAsBytes(response.bodyBytes, flush: true);

    log.info("[BackupService] done database restore");
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await MigrationUtil.getBackupDeviceID();

    return "$deviceId\_${packageInfo.packageName}";
  }
}
