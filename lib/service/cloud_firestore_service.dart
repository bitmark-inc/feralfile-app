import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/util/cloud_firestore.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CloudFirestoreService {
  FirebaseFirestore fireBaseFirestore;
  String? deviceId;

  CloudFirestoreService(this.fireBaseFirestore);

  // init service
  Future<void> initService() async {
    deviceId = await getBackupId();
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await MigrationUtil.getBackupDeviceID();

    return '${deviceId}_${packageInfo.packageName}';
  }

  CollectionReference getCollection(String collectionName) => fireBaseFirestore
      .collection('$deviceId/$virtualDocumentId/$collectionName');

  // method getBatch
  WriteBatch getBatch() => fireBaseFirestore.batch();

  // backup from sqlite clouddatabase
  Future<void> backupCloudDatabase() async {
    log.info('[CloudFirestoreService] start database backup');
    final cloudDatabase = injector<CloudDatabase>();
    final cloudFirestoreDatabase = injector<CloudDatabase>();
    try {
      final personas = await cloudDatabase.personaDao.getPersonas();
      unawaited(cloudFirestoreDatabase.personaDao.insertPersonas(personas));
      final connections =
          await cloudDatabase.connectionDao.getUpdatedLinkedAccounts();
      unawaited(
          cloudFirestoreDatabase.connectionDao.insertConnections(connections));
      final audits = await cloudDatabase.auditDao.getAudits();
      unawaited(cloudFirestoreDatabase.auditDao.insertAudits(audits));
      final addresses = await cloudDatabase.addressDao.getAllAddresses();
      unawaited(cloudFirestoreDatabase.addressDao.insertAddresses(addresses));
    } catch (err) {
      log.info('[CloudFirestoreService] error database backup, $err');
    }
    log.info('[BackupService] done database backup');
  }
}
