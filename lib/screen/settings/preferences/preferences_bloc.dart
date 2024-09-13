//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class PreferencesBloc extends AuBloc<PreferenceEvent, PreferenceState> {
  final ConfigurationService _configurationService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  List<BiometricType> _availableBiometrics = List.empty();

  PreferencesBloc(this._configurationService)
      : super(PreferenceState(false, false, false, '', false, false)) {
    on<PreferenceInfoEvent>((event, emit) async {
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      final canCheckBiometrics = await authenticateIsAvailable();

      final passcodeEnabled = _configurationService.isDevicePasscodeEnabled();
      final notificationEnabled =
          _configurationService.isNotificationEnabled() ?? false;
      final analyticsEnabled = _configurationService.isAnalyticsEnabled();

      final hasHiddenArtwork =
          _configurationService.getTempStorageHiddenTokenIDs().isNotEmpty;

      final hasPendingSettings = _configurationService.hasPendingSettings();

      emit(PreferenceState(
          passcodeEnabled && canCheckBiometrics,
          notificationEnabled,
          analyticsEnabled,
          _authMethodTitle(),
          hasHiddenArtwork,
          hasPendingSettings));
    });

    on<PreferenceUpdateEvent>((event, emit) async {
      if (event.newState.isDevicePasscodeEnabled !=
          state.isDevicePasscodeEnabled) {
        final canCheckBiometrics = await authenticateIsAvailable();
        if (canCheckBiometrics) {
          bool didAuthenticate = false;
          try {
            didAuthenticate = await LocalAuthenticationService.authenticate(
                localizedReason: 'authen_for_autonomy'.tr());
          } catch (e) {
            log.info(e);
          }
          if (didAuthenticate) {
            await _configurationService.setDevicePasscodeEnabled(
                event.newState.isDevicePasscodeEnabled);
            await _configurationService.setPendingSettings(false);
          } else {
            event.newState.isDevicePasscodeEnabled =
                state.isDevicePasscodeEnabled;
          }
        } else {
          event.newState.isDevicePasscodeEnabled = false;
          unawaited(openAppSettings());
        }
      }

      if (event.newState.isNotificationEnabled != state.isNotificationEnabled) {
        try {
          if (event.newState.isNotificationEnabled) {
            unawaited(registerPushNotifications(askPermission: true).then(
                (value) => event.newState.isNotificationEnabled == value));
          } else if (Platform.isIOS) {
            // ignore: lines_longer_than_80_chars
            // TODO: for iOS only, do not un-registry push, but silent the notification
            unawaited(deregisterPushNotification());
          }

          await _configurationService
              .setNotificationEnabled(event.newState.isNotificationEnabled);
          await _configurationService.setPendingSettings(false);
        } catch (error) {
          log.warning('Error when setting notification: $error');
        }
      }

      if (event.newState.isAnalyticEnabled != state.isAnalyticEnabled) {
        await _configurationService
            .setAnalyticEnabled(event.newState.isAnalyticEnabled);
        await _configurationService.setPendingSettings(false);
        unawaited(injector<SettingsDataService>().backup());
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
