//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';

class DisplaySettingsService {
  DisplaySettingsService(this._cloudObject);

  final CloudManager _cloudObject;

  DisplaySettings getDisplaySettings(String tokenId) {
    try {
      final userSettings =
          _cloudObject.artworkSettingsCloudObject.getDisplaySetting(tokenId);

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
    await _cloudObject.artworkSettingsCloudObject
        .updateDisplaySetting(displaySetting);
  }
}
