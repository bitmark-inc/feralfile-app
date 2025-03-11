import 'package:shared_preferences/shared_preferences.dart';

class NftCollectionPrefs {
  NftCollectionPrefs(this._prefs);

  static const _keyLastRefreshTokenTime = 'last_refresh_at';
  static const _keyDidSyncAddress = 'did_sync_address';

  final SharedPreferences _prefs;

  Future<bool> setLatestRefreshTokens(DateTime? time) async {
    if (time != null) {
      return _prefs.setInt(
        _keyLastRefreshTokenTime,
        time.millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      return _prefs.remove(_keyLastRefreshTokenTime);
    }
  }

  DateTime? getLatestRefreshTokens() {
    final timestamp = _prefs.getInt(_keyLastRefreshTokenTime);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else {
      return null;
    }
  }

  Future<bool> setDidSyncAddress(bool value) async {
    return _prefs.setBool(_keyDidSyncAddress, value);
  }

  bool getDidSyncAddress() {
    return _prefs.getBool(_keyDidSyncAddress) ?? false;
  }
}
