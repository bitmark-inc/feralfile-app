import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigurationService {
  Future<void> setAccount(String value);
  String? getAccount();
  Future<void> setPersonas(List<String> value);
  List<String> getPersonas();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_ACCOUNT = "key_account";
  static const String KEY_PERSONA = "key_persona";

  SharedPreferences _preferences;

  ConfigurationServiceImpl(this._preferences);

  @override
  Future<void> setAccount(String value) async {
    await _preferences.setString(KEY_ACCOUNT, value);
  }

  String? getAccount() {
    return _preferences.getString(KEY_ACCOUNT);
  }

  @override
  Future<void> setPersonas(List<String> value) async {
    await _preferences.setStringList(KEY_PERSONA, value);
  }

  @override
  List<String> getPersonas() {
    return _preferences.getStringList(KEY_PERSONA) ?? List.empty();
  }
}
