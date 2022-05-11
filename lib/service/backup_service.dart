import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/backup_versions.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:floor/floor.dart';
import 'package:http/http.dart' as http;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BackupService {
  final IAPApi _iapApi;

  BackupService(this._iapApi);

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

  Future<String> fetchBackupVersion(WalletStorage account) async {
    final filename = 'cloud_database.db';

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    String? deviceId = await getBackupId();
    final authToken = await getAuthToken(account);

    final endpoint = Environment.autonomyAuthURL;
    final response = await http.get(
        Uri.parse(
            "$endpoint/apis/v1/premium/profile-data/versions?filename=$filename"),
        headers: {"requester": deviceId, "Authorization": "Bearer $authToken"});

    if (response.contentLength == 0 && response.statusCode != 200) {
      log.warning("[BackupService] failed fetchBackupVersion");
      return "";
    }

    final result = BackupVersions.fromJson(json.decode(response.body));

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

  Future deleteAllProfiles(WalletStorage account) async {
    log.info("[BackupService][start] deleteAllProfiles");
    String? deviceId = await getBackupId();
    final endpoint = Environment.autonomyAuthURL;
    final authToken = await getAuthToken(account);

    await http.delete(Uri.parse("$endpoint/apis/v1/premium/profile-data"),
        headers: {"requester": deviceId, "Authorization": "Bearer $authToken"});
  }

  Future restoreCloudDatabase(WalletStorage account, String version,
      {String dbName = 'cloud_database.db'}) async {
    log.info("[BackupService] start database restore");
    final filename = 'cloud_database.db';

    String? deviceId = await getBackupId();
    final authToken = await getAuthToken(account);

    final endpoint = Environment.autonomyAuthURL;
    final response = await http.get(
        Uri.parse(
            "$endpoint/apis/v1/premium/profile-data?filename=$filename&appVersion=$version"),
        headers: {"requester": deviceId, "Authorization": "Bearer $authToken"});

    if (response.contentLength == 0 && response.statusCode != 200) {
      log.warning("[BackupService] failed database restore");
      return;
    }

    final path = await sqfliteDatabaseFactory.getDatabasePath(dbName);
    final file = File(path);

    await file.writeAsBytes(response.bodyBytes, flush: true);

    log.info("[BackupService] done database restore");
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await MigrationUtil.getBackupDeviceID();

    return "$deviceId\_${packageInfo.packageName}";
  }

  Future<String> getAuthToken(WalletStorage account) async {
    final message = DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      "requester": accountDID,
      "timestamp": message,
      "signature": signature,
    };

    final jwt = await _iapApi.auth(payload);
    return jwt.jwtToken;
  }
}
