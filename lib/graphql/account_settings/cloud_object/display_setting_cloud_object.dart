import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

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

  Future<void> updateNowDisplaySetting(
    DisplaySettings displaySetting,
  ) async {
    await _accountSettingsDB.write([
      {
        'key': ConfigurationServiceImpl.KEY_NOW_DISPLAY_SETTINGS,
        'value': displaySetting.value,
      }
    ]);
  }

  Future<void> deleteNowDisplaySetting() async {
    await _accountSettingsDB.delete([
      ConfigurationServiceImpl.KEY_NOW_DISPLAY_SETTINGS,
    ]);
  }
}
