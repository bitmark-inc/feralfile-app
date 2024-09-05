import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';

abstract class AccountSettingsDB {
  Future<void> download();

  List<Map<String, String>> query(List<String> keys);

  Future<void> write(List<Map<String, String>> settings);

  Future<void> delete(List<String> keys);
}

class AccountSettingsDBImpl implements AccountSettingsDB {
  final AccountSettingsClient _client;

  AccountSettingsDBImpl(this._client);

  final Map<String, String> _caches = {};

  @override
  Future<void> download() {
    throw UnimplementedError();
  }

  @override
  List<Map<String, String>> query(List<String> keys) => keys
      .map((key) => {'key': key, 'value': _caches[key]})
      .where((element) => element['value'] != null)
      .map((e) => e as Map<String, String>)
      .toList();

  @override
  Future<void> write(List<Map<String, String>> settings) {
    for (var element in settings) {
      _caches[element['key']!] = element['value']!;
    }
    return _client.write(data: settings);
  }

  @override
  Future<void> delete(List<String> keys) async {
    _caches.removeWhere((key, value) => keys.contains(key));
    await _client.delete(vars: {'keys': keys});
  }
}
