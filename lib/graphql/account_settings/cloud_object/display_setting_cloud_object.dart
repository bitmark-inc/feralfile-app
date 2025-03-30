import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/model/display_settings.dart';

class DisplaySettingsCloudObject {
  DisplaySettingsCloudObject(this._accountSettingsDB);
  final AccountSettingsDB _accountSettingsDB;

  AccountSettingsDB get db => _accountSettingsDB;

  DisplaySettings? getDisplaySetting(String tokenId) {
    final value = _accountSettingsDB.query([tokenId]);
    if (value.isEmpty) {
      return null;
    }

    final displaySettingJson =
        jsonDecode(value.first['value']!) as Map<String, dynamic>;
    return DisplaySettings.fromJson(displaySettingJson);
  }

  Future<void> updateDisplaySetting(
    DisplaySettings displaySetting,
  ) async {
    await _accountSettingsDB.write([displaySetting.toKeyValue]);
  }
}
