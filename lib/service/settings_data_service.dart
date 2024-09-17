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
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'settings_data_service.g.dart';

abstract class SettingsDataService {
  Future backup();

  Future restoreSettingsData({bool fromProfileData = false});

  List<String> get settingsKeys;
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
  var _numberOfCallingBackups = 0;

  static const _keyIsAnalyticsEnabled = 'isAnalyticsEnabled';
  static const _keyHiddenMainnetTokenIDs = 'hiddenMainnetTokenIDs';
  static const _keyHiddenAddressesFromGallery = 'hiddenAddressesFromGallery';
  static const _keyHiddenLinkedAccountsFromGallery =
      'hiddenLinkedAccountsFromGallery';
  static const _keyPlaylists = 'playlists';

  @override
  List<String> settingsKeys = [
    _keyIsAnalyticsEnabled,
    _keyHiddenMainnetTokenIDs,
    _keyHiddenAddressesFromGallery,
    _keyHiddenLinkedAccountsFromGallery,
    _keyPlaylists,
  ];

  @override
  Future backup() async {
    log.info('[SettingsDataService][Start] backup');
    if (_numberOfCallingBackups > 0) {
      log.info(
          "[SettingsDataService] skip backup because of it's already running");
      return;
    }
    final currentSettings = _cloudObject.settingsDataDB.allInstance;

    final List<Map<String, String>> newSettings = [];

    _numberOfCallingBackups += 1;

    final isAnalyticsEnabled =
        jsonEncode(_configurationService.isAnalyticsEnabled());
    if (currentSettings[_keyIsAnalyticsEnabled] != isAnalyticsEnabled) {
      newSettings.add({
        'key': _keyIsAnalyticsEnabled,
        'value': isAnalyticsEnabled,
      });
    }

    final hiddenMainnetTokenIDs =
        jsonEncode(_configurationService.getTempStorageHiddenTokenIDs());
    if (currentSettings[_keyHiddenMainnetTokenIDs] != hiddenMainnetTokenIDs) {
      newSettings.add({
        'key': _keyHiddenMainnetTokenIDs,
        'value': hiddenMainnetTokenIDs,
      });
    }

    final hiddenAddressesFromGallery = jsonEncode(_cloudObject.addressObject
        .findAddressesWithHiddenStatus(true)
        .map((e) => e.address)
        .toList());
    if (currentSettings[_keyHiddenAddressesFromGallery] !=
        hiddenAddressesFromGallery) {
      newSettings.add({
        'key': _keyHiddenAddressesFromGallery,
        'value': hiddenAddressesFromGallery,
      });
    }

    final hiddenLinkedAccountsFromGallery =
        jsonEncode(_configurationService.getLinkedAccountsHiddenInGallery());
    if (currentSettings[_keyHiddenLinkedAccountsFromGallery] !=
        hiddenLinkedAccountsFromGallery) {
      newSettings.add({
        'key': _keyHiddenLinkedAccountsFromGallery,
        'value': hiddenLinkedAccountsFromGallery,
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
      log.info("[SettingsDataService] skip backup because of it's identical");
      return;
    }

    try {
      await _cloudObject.settingsDataDB.write(newSettings);
    } catch (exception, stacktrace) {
      await Sentry.captureException(exception, stackTrace: stacktrace);
      return;
    }

    _numberOfCallingBackups -= 1;

    log.info('[SettingsDataService][Done] backup');
  }

  @override
  Future restoreSettingsData({bool fromProfileData = false}) async {
    log.info('[SettingsDataService][Start] restoreSettingsData');
    if (!fromProfileData) {
      log.info('[SettingsDataService] from account setting db');
      await _cloudObject.settingsDataDB.download(keys: settingsKeys);
      final res = _cloudObject.settingsDataDB.allInstance
          .map((key, value) => MapEntry(key, jsonDecode(value)));

      log.info('[SettingsDataService] restore $res');

      final data = SettingsDataBackup.fromJson(res);

      await _saveSettingToConfig(data);
    } else {
      log.info('[SettingsDataService] migrate from old server');
      try {
        final response =
            await _iapApi.getProfileData(_requester, _filename, _version);
        final data = SettingsDataBackup.fromJson(json.decode(response));

        await _saveSettingToConfig(data);

        log.info('[SettingsDataService][Done] restoreSettingsData');
      } catch (exception, stacktrace) {
        await Sentry.captureException(exception, stackTrace: stacktrace);
        return;
      }
    }
  }

  Future<void> _saveSettingToConfig(SettingsDataBackup data) async {
    await _configurationService.setAnalyticEnabled(data.isAnalyticsEnabled);

    await _configurationService.updateTempStorageHiddenTokenIDs(
        data.hiddenMainnetTokenIDs, true,
        override: true);

    await Future.wait((data.hiddenAddressesFromGallery ?? []).map(
            (e) => _cloudObject.addressObject.setAddressIsHidden(e, true)));

    await _configurationService.setHideLinkedAccountInGallery(
        data.hiddenLinkedAccountsFromGallery, true,
        override: true);

    await _configurationService.setPlayList(data.playlists, override: true);
  }
}

@JsonSerializable()
class SettingsDataBackup {
  bool isAnalyticsEnabled;
  List<String> hiddenMainnetTokenIDs;
  List<String> hiddenTestnetTokenIDs;
  List<String> hiddenLinkedAccountsFromGallery;
  List<String>? hiddenAddressesFromGallery;
  List<PlayListModel> playlists;

  SettingsDataBackup({
    required this.isAnalyticsEnabled,
    required this.hiddenMainnetTokenIDs,
    required this.hiddenTestnetTokenIDs,
    required this.hiddenLinkedAccountsFromGallery,
    this.hiddenAddressesFromGallery,
    this.playlists = const [],
  });

  factory SettingsDataBackup.fromJson(Map<String, dynamic> json) =>
      _$SettingsDataBackupFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsDataBackupToJson(this);
}
