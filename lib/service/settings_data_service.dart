//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class SettingsDataService {
  Future restoreSettingsData({bool fromProfileData = false});

  Future<void> backupDeviceSettings();

  Future<void> backupUserSettings();
}

class SettingsDataServiceImpl implements SettingsDataService {
  final ConfigurationService _configurationService;
  final IAPApi _iapApi;
  final CloudManager _cloudObject;

  SettingsDataServiceImpl(
    this._configurationService,
    this._iapApi,
    this._cloudObject,
  );

  final _requester =
      'requester'; // server ignore this when putting jwt, so just put something
  final _filename = 'settings_data_backup.json';
  final _version = '1';

  // device settings
  static const _keyIsAnalyticsEnabled = 'isAnalyticsEnabled';
  static const _keyDevicePasscodeEnabled = 'devicePasscodeEnabled';
  static const _keyNotificationEnabled = 'notificationEnabled';
  static const _deviceSettingsKeys = [
    _keyIsAnalyticsEnabled,
    _keyDevicePasscodeEnabled,
    _keyNotificationEnabled,
  ];

  // user settings
  static const _keyPlaylists = 'playlists';
  static const _keyHiddenMainnetTokenIDs = 'hiddenMainnetTokenIDs';

  static const _userSettingsKeys = [
    _keyPlaylists,
    _keyHiddenMainnetTokenIDs,
  ];

  @override
  Future restoreSettingsData({bool fromProfileData = false}) async {
    if (PreferencesBloc.isOnChanging) {
      log.info('[SettingsDataService] skip restore: on changing preference');
      return;
    }
    log.info('[SettingsDataService][Start] restoreSettingsData');
    if (!fromProfileData) {
      log.info('[SettingsDataService] from account setting db');
      await Future.wait([
        _cloudObject.deviceSettingsDB.download(keys: _deviceSettingsKeys),
        _cloudObject.userSettingsDB.download(keys: _userSettingsKeys),
      ]);
      final Map<String, dynamic> data = {}
        ..addAll(_cloudObject.deviceSettingsDB.allInstance
            .map((key, value) => MapEntry(key, jsonDecode(value))))
        ..addAll(_cloudObject.userSettingsDB.allInstance
            .map((key, value) => MapEntry(key, jsonDecode(value))));

      log.info('[SettingsDataService] restore $data');

      await _saveSettingToConfig(data);
    } else {
      log.info('[SettingsDataService] migrate from old server');
      try {
        final response =
            await _iapApi.getProfileData(_requester, _filename, _version);
        final data = json.decode(response);

        await _saveSettingToConfig(data);

        log.info('[SettingsDataService][Done] restoreSettingsData');
      } catch (exception, stacktrace) {
        await Sentry.captureException(exception, stackTrace: stacktrace);
        return;
      }
    }
  }

  Future<void> _saveSettingToConfig(Map<String, dynamic> data) async {
    await _configurationService
        .setAnalyticEnabled(data[_keyIsAnalyticsEnabled] as bool? ?? true);

    await _configurationService.setDevicePasscodeEnabled(
        data[_keyDevicePasscodeEnabled] as bool? ?? false);

    await _configurationService
        .setNotificationEnabled(data[_keyNotificationEnabled] as bool? ?? true);

    await _configurationService.updateTempStorageHiddenTokenIDs(
        (data[_keyHiddenMainnetTokenIDs] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        true,
        override: true);

    await _configurationService.setPlayList(
        (data[_keyPlaylists] as List<dynamic>?)
                ?.map(
                  (e) => PlayListModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        override: true);
  }

  @override
  Future<void> backupDeviceSettings() async {
    final currentSettings = _cloudObject.deviceSettingsDB.allInstance;
    final List<Map<String, String>> newSettings = [];

    final isAnalyticsEnabled =
        jsonEncode(_configurationService.isAnalyticsEnabled());
    if (currentSettings[_keyIsAnalyticsEnabled] != isAnalyticsEnabled) {
      newSettings.add({
        'key': _keyIsAnalyticsEnabled,
        'value': isAnalyticsEnabled,
      });
    }

    final devicePasscodeEnabled =
        jsonEncode(_configurationService.isDevicePasscodeEnabled());
    if (currentSettings[_keyDevicePasscodeEnabled] != devicePasscodeEnabled) {
      newSettings.add({
        'key': _keyDevicePasscodeEnabled,
        'value': devicePasscodeEnabled,
      });
    }

    final notificationEnabled =
        jsonEncode(_configurationService.isNotificationEnabled());
    if (currentSettings[_keyNotificationEnabled] != notificationEnabled) {
      newSettings.add({
        'key': _keyNotificationEnabled,
        'value': notificationEnabled,
      });
    }

    if (newSettings.isEmpty) {
      log.info('[SettingsDataService] skip device backup: identical');
      return;
    }

    try {
      await _cloudObject.deviceSettingsDB.write(newSettings);

      log.info('[SettingsDataService][Done] backup device settings');
    } catch (exception, stacktrace) {
      await Sentry.captureException(exception, stackTrace: stacktrace);
      return;
    }
  }

  @override
  Future<void> backupUserSettings() async {
    final currentSettings = _cloudObject.userSettingsDB.allInstance;
    final List<Map<String, String>> newSettings = [];

    final hiddenMainnetTokenIDs =
        jsonEncode(_configurationService.getTempStorageHiddenTokenIDs());
    if (currentSettings[_keyHiddenMainnetTokenIDs] != hiddenMainnetTokenIDs) {
      newSettings.add({
        'key': _keyHiddenMainnetTokenIDs,
        'value': hiddenMainnetTokenIDs,
      });
    }

    final playlists = jsonEncode(_configurationService.getPlayList());
    if (currentSettings[_keyPlaylists] != playlists) {
      newSettings.add({
        'key': _keyPlaylists,
        'value': playlists,
      });
    }

    if (newSettings.isEmpty) {
      log.info('[SettingsDataService] skip user backup: identical');
      return;
    }

    try {
      await _cloudObject.userSettingsDB.write(newSettings);

      log.info('[SettingsDataService][Done] backup user settings');
    } catch (exception, stacktrace) {
      await Sentry.captureException(exception, stackTrace: stacktrace);
      return;
    }
  }
}
