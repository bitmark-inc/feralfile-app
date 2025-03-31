import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class DisplaySettingsService {
  DisplaySettingsService(this._cloudObject, this._configurationService);

  final CloudManager _cloudObject;
  final ConfigurationService _configurationService;

  DisplaySettings getDisplaySettings(String tokenId) {
    try {
      final userSettings =
          _configurationService.getArtworkDisplaySettings(tokenId);

      if (userSettings != null) {
        return userSettings;
      }

      final deviceStatus =
          injector<FFBluetoothService>().bluetoothDeviceStatus.value;
      return DisplaySettings(
        tokenId: tokenId,
        viewMode: (deviceStatus?.artFraming == ArtFraming.cropToFill)
            ? ArtFraming.cropToFill
            : ArtFraming.fitToScreen,
        rotationAngle: 0,
      );
    } catch (e) {
      return DisplaySettings.defaultSettings(tokenId);
    }
  }

  Future<void> updateDisplaySetting(
    DisplaySettings displaySetting,
  ) async {
    await _configurationService.setArtworkDisplaySettings(displaySetting);
    unawaited(
      _cloudObject.artworkSettingsCloudObject
          .updateDisplaySetting(displaySetting),
    );
  }

  DisplaySettings getNowDisplaySettings(String tokenId) {
    try {
      final nowDisplaySettings = _configurationService.getNowDisplaySettings();
      if (nowDisplaySettings != null) {
        return nowDisplaySettings;
      }

      final deviceStatus =
          injector<FFBluetoothService>().bluetoothDeviceStatus.value;
      return DisplaySettings(
        tokenId: tokenId,
        viewMode: (deviceStatus?.artFraming == ArtFraming.cropToFill)
            ? ArtFraming.cropToFill
            : ArtFraming.fitToScreen,
        rotationAngle: 0,
      );
    } catch (e) {
      return DisplaySettings.defaultSettings(tokenId);
    }
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
