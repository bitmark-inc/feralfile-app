import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';

abstract class AccountSettingsDB {
  Future<void> download({List<String>? keys});

  Future<void> forceUpload();

  List<Map<String, String>> query(List<String> keys);

  Future<void> write(List<Map<String, String>> settings);

  Future<void> delete(List<String> keys);

  Map<String, dynamic> get caches;

  Future<bool> didMigrate();

  Future<void> setMigrated();

  String getFullKey(String key);

  String get migrateKey;

  String get prefix;

  void clearCache();
}

class AccountSettingsDBImpl implements AccountSettingsDB {
  final AccountSettingsClient _client;
  final String _prefix;

  AccountSettingsDBImpl(this._client, this._prefix);

  final Map<String, String> _caches = {};

  static const String _migrateKey = 'didMigrate';

  @override
  Future<void> download({List<String>? keys}) async {
    late List<Map<String, String>> values;
    if (keys != null) {
      values =
          await _client.query(vars: {'keys': keys.map(getFullKey).toList()});
    } else {
      values = await _client.query(vars: {'search': '$_prefix.'});
    }
    for (var value in values) {
      if (value['key'] == null || value['value'] == null) {
        continue;
      }
      _caches[_removePrefix(value['key']!)] = value['value']!;
    }
  }

  @override
  Future<void> forceUpload() async {
    final List<Map<String, String>> data = [];
    _caches.forEach((key, value) {
      data.add({'key': getFullKey(key), 'value': value});
    });
    await write(data);
  }

  @override
  List<Map<String, String>> query(List<String> keys) => keys
      .map((key) => {'key': key, 'value': _caches[key]})
      .where((element) => element['value'] != null)
      .map((e) => {'key': e['key']!, 'value': e['value']!})
      .toList();

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
        _caches[_removePrefix(element['key']!)] = element['value']!;
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
    if (isSuccess) {
      _caches.removeWhere((key, value) => keys.contains(key));
    }
  }

  @override
  String getFullKey(String key) {
    if (key.startsWith(_prefix)) {
      return key;
    }
    return '$_prefix.$key';
  }

  String _removePrefix(String key) => key.replaceFirst('$_prefix.', '');

  @override
  Map<String, dynamic> get caches => _caches;

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
  void clearCache() {
    _caches.clear();
  }

  @override
  String get prefix => _prefix;

  @override
  String get migrateKey => _migrateKey;
}
