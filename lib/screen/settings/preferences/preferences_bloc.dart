import 'dart:io';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class PreferencesBloc extends Bloc<PreferenceEvent, PreferenceState> {
  ConfigurationService _configurationService;
  AppDatabase _appDatabase;
  LocalAuthentication _localAuth = LocalAuthentication();
  List<BiometricType> _availableBiometrics = List.empty();

  PreferencesBloc(this._configurationService, this._appDatabase)
      : super(PreferenceState(false, false, false, false, "", false)) {
    on<PreferenceInfoEvent>((event, emit) async {
      final isImmediatePlaybackEnabled =
          _configurationService.isImmediatePlaybackEnabled();

      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      final canCheckBiometrics = await authenticateIsAvailable();

      final passcodeEnabled = _configurationService.isDevicePasscodeEnabled();
      final notificationEnabled =
          _configurationService.isNotificationEnabled() ?? false;
      final analyticsEnabled = _configurationService.isAnalyticsEnabled();

      final numOfHiddenArtworks =
          await _appDatabase.assetDao.findNumOfHiddenAssets();

      final hasHiddenArtwork =
          numOfHiddenArtworks != null && numOfHiddenArtworks > 0;

      emit(PreferenceState(
          isImmediatePlaybackEnabled,
          passcodeEnabled && canCheckBiometrics,
          notificationEnabled,
          analyticsEnabled,
          _authMethodTitle(),
          hasHiddenArtwork));
    });

    on<PreferenceUpdateEvent>((event, emit) async {
      if (event.newState.isImmediatePlaybackEnabled !=
          state.isImmediatePlaybackEnabled) {
        await _configurationService.setImmediatePlaybackEnabled(
            event.newState.isImmediatePlaybackEnabled);
      }

      if (event.newState.isDevicePasscodeEnabled !=
          state.isDevicePasscodeEnabled) {
        final canCheckBiometrics = await authenticateIsAvailable();
        if (canCheckBiometrics) {
          if (state.isDevicePasscodeEnabled) {
            final didAuthenticate = await _localAuth.authenticate(
                localizedReason: 'Authentication for "Autonomy"');
            if (didAuthenticate) {
              await _configurationService.setDevicePasscodeEnabled(
                  event.newState.isDevicePasscodeEnabled);
            } else {
              event.newState.isDevicePasscodeEnabled =
                  state.isDevicePasscodeEnabled;
            }
          } else {
            await _configurationService.setDevicePasscodeEnabled(
                event.newState.isDevicePasscodeEnabled);
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
          } else {
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
      }

      emit(event.newState);
    });
  }

  String _authMethodTitle() {
    if (Platform.isIOS) {
      if (_availableBiometrics.contains(BiometricType.face)) {
        // Face ID.
        return 'Face ID';
      } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
        // Touch ID.
        return 'Touch ID';
      }
    }

    return 'Device Passcode';
  }
}
