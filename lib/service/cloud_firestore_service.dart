import 'package:autonomy_flutter/util/cloud_firestore.dart';
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
}
