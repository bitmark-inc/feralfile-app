import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';

class MockCloudDB extends CloudDB {
  @override
  Future<void> download({List<String>? keys}) async {}

  @override
  Future<void> uploadCurrentCache() async {}

  @override
  List<Map<String, String>> query(List<String> keys) => [];

  @override
  Future<void> write(List<Map<String, String>> settings,
      {OnConflict onConflict = OnConflict.override}) async {}

  @override
  Future<bool> delete(List<String> keys) async => true;

  @override
  Future<bool> didMigrate() async => true;

  @override
  Future<void> setMigrated() async {}

  @override
  String getFullKey(String key) => key;

  @override
  String get migrateKey => 'migrateKey';

  @override
  String get prefix => 'prefix';

  @override
  List<String> get keys => [];

  @override
  List<String> get values => [];

  @override
  Map<String, String> get allInstance => {};

  @override
  void clearCache() {}

  @override
  Future<void> deleteAll() async {}
}
