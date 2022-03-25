import 'dart:convert';

import 'package:flutter/services.dart';

class AndroidBackupChannel {
  static const MethodChannel _channel = const MethodChannel('backup');

  Future<bool> isEndToEndEncryptionAvailable() async {
    return await _channel.invokeMethod('isEndToEndEncryptionAvailable', {});
  }

  Future backupKeys(List<String> uuids) async {
    await _channel.invokeMethod('backupKeys', {"uuids": uuids});
  }

  Future<List<BackupAccount>> restoreKeys() async {
    String data = await _channel.invokeMethod('restoreKeys', {});
    if (data.isEmpty) {
      return [];
    }
    final backupData = json.decode(data);
    return BackupData.fromJson(backupData).accounts;
  }
}

class BackupData {
  BackupData({
    required this.accounts,
  });

  List<BackupAccount> accounts;

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    accounts: List<BackupAccount>.from(json["accounts"].map((x) => BackupAccount.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "accounts": accounts,
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
    uuid: json["uuid"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "uuid": uuid,
    "name": name,
  };
}