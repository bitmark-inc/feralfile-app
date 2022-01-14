import 'dart:convert';

import 'package:autonomy_flutter/model/account.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setAccount(Account value);
  Account? getAccount();
  Future<void> setPersonas(List<String> value);
  List<String> getPersonas();
  Future<void> setWCSessions(List<WCSessionStore> value);
  List<WCSessionStore> getWCSessions();
  Future<void> setNetwork(Network value);
  Network getNetwork();
  Future<void> setDevicePasscodeEnabled(bool value);
  bool isDevicePasscodeEnabled();
  Future<void> setNotificationEnabled(bool value);
  bool isNotificationEnabled();
  Future<void> setAnalyticEnabled(bool value);
  bool isAnalyticsEnabled();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_ACCOUNT = "key_account";
  static const String KEY_PERSONA = "key_persona";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";
  static const String KEY_NETWORK = "key_network";
  static const String KEY_DEVICE_PASSCODE = "device_passcode";
  static const String KEY_NOTIFICATION = "notifications";
  static const String KEY_ANALYTICS = "analytics";

  SharedPreferences _preferences;

  ConfigurationServiceImpl(this._preferences);

  @override
  Future<void> setAccount(Account value) async {
    final json = jsonEncode(value);
    await _preferences.setString(KEY_ACCOUNT, json);
  }

  @override
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

  @override
  Future<void> setWCSessions(List<WCSessionStore> value) async {
    final json = jsonEncode(value);
    await _preferences.setString(KEY_WC_SESSIONS, json);
  }

  @override
  List<WCSessionStore> getWCSessions() {
    final json = _preferences.getString(KEY_WC_SESSIONS);
    final sessions = json != null ? jsonDecode(json) : List.empty();
    return List.from(sessions).map((e) => WCSessionStore.fromJson(e)).toList(growable: false);
  }

  @override
  Future<void> setNetwork(Network value) async {
    await _preferences.setString(KEY_NETWORK, value.toString());
  }

  @override
  Network getNetwork() {
    final value = _preferences.getString(KEY_NETWORK) ?? Network.MAINNET.toString();
    try {
      return Network.values.firstWhere((element) => element.toString() == value);
    } catch (e) {
      return Network.MAINNET;
    }
  }

  @override
  bool isDevicePasscodeEnabled() {
    return _preferences.getBool(KEY_DEVICE_PASSCODE) ?? true;
  }

  @override
  Future<void> setDevicePasscodeEnabled(bool value) async {
    await _preferences.setBool(KEY_DEVICE_PASSCODE, value);
  }

  @override
  bool isAnalyticsEnabled() {
    return _preferences.getBool(KEY_ANALYTICS) ?? true;
  }

  @override
  bool isNotificationEnabled() {
    return _preferences.getBool(KEY_NOTIFICATION) ?? true;
  }

  @override
  Future<void> setAnalyticEnabled(bool value) async {
    await _preferences.setBool(KEY_ANALYTICS, value);
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    await _preferences.setBool(KEY_NOTIFICATION, value);
  }
}
