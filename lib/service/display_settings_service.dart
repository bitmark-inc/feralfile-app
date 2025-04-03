import 'dart:async';

import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class DisplaySettingsService {
  DisplaySettingsService(this._cloudObject, this._configurationService);

  final CloudManager _cloudObject;
  final ConfigurationService _configurationService;

  Future<void> updateDisplaySetting(
    DisplaySettings displaySetting,
  ) async {
    await _configurationService.setArtworkDisplaySettings(displaySetting);
    unawaited(
      _cloudObject.artworkSettingsCloudObject
          .updateDisplaySetting(displaySetting),
    );
  }

  Future<void> updateNowDisplaySetting(
    DisplaySettings displaySetting,
  ) async {
    await _configurationService.setNowDisplaySettings(displaySetting);
    unawaited(
      _cloudObject.artworkSettingsCloudObject
          .updateNowDisplaySetting(displaySetting),
    );
  }

  Future<void> deleteNowDisplaySetting() async {
    await _configurationService.deleteNowDisplaySettings();
    unawaited(
      _cloudObject.artworkSettingsCloudObject.deleteNowDisplaySetting(),
    );
  }
}
