import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';

abstract class AccountSettingsDB {
  Future<void> download();

  Future<void> forceUpload();

  List<Map<String, String>> query(List<String> keys);

  Future<void> write(List<Map<String, String>> settings);

  Future<void> delete(List<String> keys);

  Map<String, dynamic> get caches;

  Future<bool> didMigrate();

  Future<void> setMigrated();

  String getFullKey(String key);

  String get migrateKey;

  void clearCache();
}

class AccountSettingsDBImpl implements AccountSettingsDB {
  final AccountSettingsClient _client;
  final String _prefix;

  AccountSettingsDBImpl(this._client, this._prefix);

  final Map<String, String> _caches = {};

  @override
  Future<void> download() async {
    final values = await _client.query(vars: {'search': '$_prefix.'});
    for (var value in values) {
      if (value['key'] == null) {
        continue;
      }
      _caches[value['key']!] = value['value'] ?? '';
    }
  }

  @override
  Future<void> forceUpload() async {
    final List<Map<String, String>> data = [];
    _caches.forEach((key, value) {
      data.add({'key': key, 'value': value});
    });
    await write(data);
  }

  @override
  List<Map<String, String>> query(List<String> keys) {
    final fullKeys = keys.map(getFullKey).toList();
    return fullKeys
        .map((key) => {'key': key, 'value': _caches[key]})
        .where((element) => element['value'] != null)
        .map((e) => e as Map<String, String>)
        .toList();
  }

  @override
  Future<void> write(List<Map<String, String>> settings) async {
    settings.removeWhere(
        (element) => element['key'] == null || element['value'] == null);
    final settingsFullKeys = settings
        .map((e) => {'key': getFullKey(e['key']!), 'value': e['value']!})
        .toList();
    final isSuccess = await _client.write(data: settingsFullKeys);
    if (isSuccess) {
      for (var element in settingsFullKeys) {
        _caches[element['key']!] = element['value']!;
      }
    }
  }

  @override
  Future<void> delete(List<String> keys) async {
    if (keys.isEmpty) {
      return;
    }
    final fullKeys = keys.map(getFullKey).toList();
    final isSuccess = await _client.delete(vars: {'keys': fullKeys});
    if (!isSuccess) {
      _caches.removeWhere((key, value) => fullKeys.contains(key));
    }
  }

  @override
  String getFullKey(String key) {
    if (key.startsWith(_prefix)) {
      return key;
    }
    return '$_prefix.$key';
  }

  @override
  Map<String, dynamic> get caches =>
      _caches.map((key, value) => MapEntry(getFullKey(key), value));

  @override
  Future<bool> didMigrate() async {
    if (_caches[migrateKey] == 'true') {
      return true;
    }
    final res = await _client.query(vars: {
      'keys': [getFullKey(migrateKey)]
    });

    return res.isNotEmpty && res.first['value'] == 'true';
  }

  @override
  Future<void> setMigrated() async {
    await write([
      {'key': migrateKey, 'value': 'true'}
    ]);
  }

  @override
  String get migrateKey => getFullKey('didMigrate');

  @override
  void clearCache() {
    _caches.clear();
  }
}