//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:permission_handler/permission_handler.dart';

class PreferencesBloc extends AuBloc<PreferenceEvent, PreferenceState> {
  final ConfigurationService _configurationService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  List<BiometricType> _availableBiometrics = List.empty();

  PreferencesBloc(this._configurationService)
      : super(PreferenceState(false, false, false, false, "", false)) {
    on<PreferenceInfoEvent>((event, emit) async {
      final isImmediateInfoViewEnabled =
          _configurationService.isImmediateInfoViewEnabled();

      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      final canCheckBiometrics = await authenticateIsAvailable();

      final passcodeEnabled = _configurationService.isDevicePasscodeEnabled();
      final notificationEnabled =
          _configurationService.isNotificationEnabled() ?? false;
      final analyticsEnabled = _configurationService.isAnalyticsEnabled();

      final hasHiddenArtwork =
          _configurationService.getTempStorageHiddenTokenIDs().isNotEmpty;

      emit(PreferenceState(
          isImmediateInfoViewEnabled,
          passcodeEnabled && canCheckBiometrics,
          notificationEnabled,
          analyticsEnabled,
          _authMethodTitle(),
          hasHiddenArtwork));
    });

    on<PreferenceUpdateEvent>((event, emit) async {
      if (event.newState.isImmediateInfoViewEnabled !=
          state.isImmediateInfoViewEnabled) {
        await _configurationService.setImmediateInfoViewEnabled(
            event.newState.isImmediateInfoViewEnabled);
      }

      if (event.newState.isDevicePasscodeEnabled !=
          state.isDevicePasscodeEnabled) {
        final canCheckBiometrics = await authenticateIsAvailable();
        if (canCheckBiometrics) {
          final didAuthenticate = await _localAuth.authenticate(
              localizedReason: "authen_for_autonomy".tr());
          if (didAuthenticate) {
            await _configurationService.setDevicePasscodeEnabled(
                event.newState.isDevicePasscodeEnabled);
          } else {
            event.newState.isDevicePasscodeEnabled =
                state.isDevicePasscodeEnabled;
          }
        } else {
          event.newState.isDevicePasscodeEnabled = false;
          openAppSettings();
        }
      }

      if (event.newState.isNotificationEnabled != state.isNotificationEnabled) {
        try {
          if (event.newState.isNotificationEnabled == true) {
            registerPushNotifications(askPermission: true)
                .then((value) => event.newState.isNotificationEnabled == value);
          } else if (Platform.isIOS) {
            // TODO: for iOS only, do not un-registry push, but silent the notification
            deregisterPushNotification();
          }

          await _configurationService
              .setNotificationEnabled(event.newState.isNotificationEnabled);
        } catch (error) {
          log.warning("Error when setting notification: $error");
        }
      }

      if (event.newState.isAnalyticEnabled != state.isAnalyticEnabled) {
        await _configurationService
            .setAnalyticEnabled(event.newState.isAnalyticEnabled);
        injector<SettingsDataService>().backup();
      }

      emit(event.newState);
    });
  }

  String _authMethodTitle() {
    if (Platform.isIOS) {
      if (_availableBiometrics.contains(BiometricType.face)) {
        // Face ID.
        return 'face_id'.tr();
      } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
        // Touch ID.
        return 'touch_id'.tr();
      }
    }

    return 'device_passcode'.tr();
  }
}
