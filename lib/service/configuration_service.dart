import 'dart:convert';

import 'package:autonomy_flutter/model/account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setAccount(Account value);
  Account? getAccount();
  Future<void> setPersonas(List<String> value);
  List<String> getPersonas();
  Future<void> setWCSessions(List<WCSessionStore> value);
  List<WCSessionStore> getWCSessions();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_ACCOUNT = "key_account";
  static const String KEY_PERSONA = "key_persona";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";

  SharedPreferences _preferences;

  ConfigurationServiceImpl(this._preferences);

  @override
  Future<void> setAccount(Account value) async {
    final json = jsonEncode(value);
    await _preferences.setString(KEY_ACCOUNT, json);
  }

  Account? getAccount() {
    final data = _preferences.getString(KEY_ACCOUNT);
    if (data == null) {
      return null;
    } else {
      final json = jsonDecode(data);
      return Account.fromJson(json);
    }
  }

  @override
  Future<void> setPersonas(List<String> value) async {
    await _preferences.setStringList(KEY_PERSONA, value);
  }

  @override
  List<String> getPersonas() {
    return _preferences.getStringList(KEY_PERSONA) ?? List.empty();
  }

  Future<void> setWCSessions(List<WCSessionStore> value) async {
    final json = jsonEncode(value);
    await _preferences.setString(KEY_WC_SESSIONS, json);
  }

  List<WCSessionStore> getWCSessions() {
    final json = _preferences.getString(KEY_WC_SESSIONS);
    final sessions = json != null ? jsonDecode(json) : List.empty();
    return List.from(sessions).map((e) => WCSessionStore.fromJson(e)).toList(growable: false);
  }
}
