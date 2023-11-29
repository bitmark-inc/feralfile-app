import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/sqlite_cloud_database.dart';
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

  Future<void> setAlreadyBackupFromSqlite({bool value = true}) async {
    final collection = getCollection(FirestoreCollection.firestoreSetting);
    final doc = collection.doc('backup');
    await doc.set({'backup': value});
  }

  Future<bool> isAlreadyBackupFromSqlite() async {
    final collection = getCollection(FirestoreCollection.firestoreSetting);
    final doc = collection.doc('backup');
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      return false;
    }
    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['backup'] ?? false;
  }

  CollectionReference _userCollection() => fireBaseFirestore
      .collection('$mobileAppCloudDatabase/$virtualDocumentId/$deviceId');

  CollectionReference getCollection(FirestoreCollection collection) =>
      fireBaseFirestore.collection(
          '${_userCollection().path}/$virtualDocumentId/${collection.name}');

  // method getBatch
  WriteBatch getBatch() => fireBaseFirestore.batch();

  // backup from sqlite clouddatabase
  Future<void> backupCloudDatabase(
      {required SqliteCloudDatabase sqliteCloudDatabase}) async {
    log.info('[CloudFirestoreService] start database backup');
    final cloudFirestoreDatabase = injector<CloudDatabase>();
    try {
      final personas = await sqliteCloudDatabase.personaDao.getPersonas();
      await cloudFirestoreDatabase.personaDao.insertPersonas(personas);
      final connections =
          await sqliteCloudDatabase.connectionDao.getUpdatedLinkedAccounts();

      await cloudFirestoreDatabase.connectionDao.insertConnections(connections);
      final audits = await sqliteCloudDatabase.auditDao.getAudits();
      await cloudFirestoreDatabase.auditDao.insertAudits(audits);
      final addresses = await sqliteCloudDatabase.addressDao.getAllAddresses();
      await cloudFirestoreDatabase.addressDao.insertAddresses(addresses);
    } catch (err) {
      log.info('[CloudFirestoreService] error database backup, $err');
    }
    log.info('[BackupService] done database backup');
  }

  Future removeAll() {
    final collection = _userCollection();
    return collection.get().then((snapshot) {
      final batch = getBatch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      return batch.commit();
    });
  }
}

enum FirestoreCollection {
  persona,
  connection,
  audit,
  walletAddress,
  settingsData,
  firestoreSetting;

  String get name {
    switch (this) {
      case FirestoreCollection.persona:
        return 'personas';
      case FirestoreCollection.connection:
        return 'connections';
      case FirestoreCollection.audit:
        return 'audit';
      case FirestoreCollection.walletAddress:
        return 'wallet_address';
      case FirestoreCollection.settingsData:
        return 'settings_data';
      case FirestoreCollection.firestoreSetting:
        return 'firestore_setting';
    }
  }
}
