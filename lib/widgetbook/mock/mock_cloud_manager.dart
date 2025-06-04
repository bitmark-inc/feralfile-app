import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/playlist_cloud_object.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'mock_wallet_data.dart';

class MockCloudManager extends CloudManager {
  MockCloudManager() : super();
  //save ff device
  final CloudDB _ffDeviceCloudDB = MockFFDeviceCloudDB();
  @override
  CloudDB get ffDeviceDB => _ffDeviceCloudDB;

  //save playlist
  final _playlistCloudObject = PlaylistCloudObject(MockPlaylistCloudDB());
  @override
  PlaylistCloudObject get playlistCloudObject => _playlistCloudObject;
}

class MockFFDeviceCloudDB extends CloudDB {
  MockFFDeviceCloudDB() : super();

  final Map<String, String> _cache = {};
  static const String _prefix = 'mock.ff.device';
  static const String _migrateKey = 'didMigrate';

  @override
  List<String> get keys =>
      _cache.keys.where((key) => key != _migrateKey).toList();

  @override
  Map<String, String> get allInstance => Map.from(_cache);

  @override
  void clearCache() {
    _cache.clear();
  }

  @override
  Future<void> deleteAll() async {
    _cache.clear();
  }

  @override
  Future<bool> didMigrate() async {
    return _cache[_migrateKey] == 'true';
  }

  @override
  Future<void> download({List<String>? keys}) async {
    // Mock implementation - no actual download needed
  }

  @override
  String getFullKey(String key) {
    if (key.startsWith(_prefix)) {
      return key;
    }
    return '$_prefix.$key';
  }

  @override
  String get migrateKey => _migrateKey;

  @override
  String get prefix => _prefix;

  @override
  List<Map<String, String>> query(List<String> keys) {
    return keys
        .map((key) => {'key': key, 'value': _cache[key]})
        .where((element) => element['value'] != null)
        .map((e) => {'key': e['key']!, 'value': e['value']!})
        .toList();
  }

  @override
  Future<void> setMigrated() async {
    _cache[_migrateKey] = 'true';
  }

  @override
  Future<void> uploadCurrentCache() async {
    // Mock implementation - no actual upload needed
  }

  @override
  List<String> get values => _cache.values.toList();

  @override
  Future<void> write(List<Map<String, String>> settings,
      {OnConflict onConflict = OnConflict.override}) async {
    for (var setting in settings) {
      if (setting['key'] == null || setting['value'] == null) continue;
      if (onConflict == OnConflict.skip && _cache.containsKey(setting['key'])) {
        continue;
      }
      _cache[setting['key']!] = setting['value']!;
    }
  }

  @override
  Future<bool> delete(List<String> keys) async {
    for (var key in keys) {
      _cache.remove(key);
    }
    return true;
  }
}

// mock playlist db
class MockPlaylistCloudDB extends CloudDB {
  MockPlaylistCloudDB() : super();

  final Map<String, String> _cache = {};
  static const String _prefix = 'mock.playlist';
  static const String _migrateKey = 'didMigrate';

  @override
  List<String> get keys =>
      _cache.keys.where((key) => key != _migrateKey).toList();

  @override
  Map<String, String> get allInstance => Map.from(_cache);

  @override
  void clearCache() {
    _cache.clear();
  }

  @override
  Future<void> deleteAll() async {
    _cache.clear();
  }

  @override
  Future<bool> didMigrate() async {
    return _cache[_migrateKey] == 'true';
  }

  @override
  Future<void> download({List<String>? keys}) async {
    // Mock implementation - no actual download needed
  }

  @override
  String getFullKey(String key) {
    if (key.startsWith(_prefix)) {
      return key;
    }
    return '$_prefix.$key';
  }

  @override
  String get migrateKey => _migrateKey;

  @override
  String get prefix => _prefix;

  @override
  List<Map<String, String>> query(List<String> keys) {
    return keys
        .map((key) => {'key': key, 'value': _cache[key]})
        .where((element) => element['value'] != null)
        .map((e) => {'key': e['key']!, 'value': e['value']!})
        .toList();
  }

  @override
  Future<void> setMigrated() async {
    _cache[_migrateKey] = 'true';
  }

  @override
  Future<void> uploadCurrentCache() async {
    // Mock implementation - no actual upload needed
  }

  @override
  List<String> get values => _cache.values.toList();

  @override
  Future<void> write(List<Map<String, String>> settings,
      {OnConflict onConflict = OnConflict.override}) async {
    for (var setting in settings) {
      if (setting['key'] == null || setting['value'] == null) continue;
      if (onConflict == OnConflict.skip && _cache.containsKey(setting['key'])) {
        continue;
      }
      _cache[setting['key']!] = setting['value']!;
    }
  }

  @override
  Future<bool> delete(List<String> keys) async {
    for (var key in keys) {
      _cache.remove(key);
    }
    return true;
  }
}
