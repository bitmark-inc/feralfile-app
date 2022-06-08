//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:autonomy_flutter/util/log.dart';

part 'settings_data_service.g.dart';

abstract class SettingsDataService {
  Future backup();
  Future restoreSettingsData();
}

class SettingsDataServiceImpl implements SettingsDataService {
  final ConfigurationService _configurationService;
  final AssetTokenDao _mainnetAssetDao;
  final AssetTokenDao _testnetAssetDao;
  final IAPApi _iapApi;
  SettingsDataServiceImpl(
    this._configurationService,
    this._mainnetAssetDao,
    this._testnetAssetDao,
    this._iapApi,
  );

  final _requester =
      'requester'; // server ignore this when putting jwt, so just put something
  final _filename = 'settings_data_backup.json';
  final _version = '0';
  var _numberOfCallingBackups = 0;

  @override
  Future backup() async {
    log.info('[SettingsDataService][Start] backup');
    _numberOfCallingBackups += 1;
    final hiddenMainnetTokenIDs =
        (await _mainnetAssetDao.findAllHiddenTokenIDs() +
                _configurationService.getTempStorageHiddenTokenIDs(
                    network: Network.MAINNET))
            .toSet()
            .toList();

    final hiddenTestnetTokenIDs =
        (await _testnetAssetDao.findAllHiddenTokenIDs() +
                _configurationService.getTempStorageHiddenTokenIDs(
                    network: Network.TESTNET))
            .toSet()
            .toList();

    final data = SettingsDataBackup(
      immediatePlaybacks: _configurationService.isImmediatePlaybackEnabled(),
      isAnalyticsEnabled: _configurationService.isAnalyticsEnabled(),
      uxGuideStep: _configurationService.getUXGuideStep(),
      finishedSurveys: _configurationService.getFinishedSurveys(),
      hiddenMainnetTokenIDs: hiddenMainnetTokenIDs,
      hiddenTestnetTokenIDs: hiddenTestnetTokenIDs,
      hiddenFullAccountsFromGallery:
          _configurationService.getPersonaUUIDsHiddenInGallery(),
      hiddenLinkedAccountsFromGallery:
          _configurationService.getLinkedAccountsHiddenInGallery(),
    );

    String dir = (await getTemporaryDirectory()).path;
    File backupFile = new File('$dir/$_filename');
    await backupFile.writeAsBytes(json.encode(data.toJson()).codeUnits);

    await _iapApi.uploadProfile(_requester, _filename, _version, backupFile);

    if (_numberOfCallingBackups == 1) {
      backupFile.delete();
    }

    _numberOfCallingBackups -= 1;

    log.info('[SettingsDataService][Done] backup');
  }

  Future restoreSettingsData() async {
    log.info('[SettingsDataService][Start] restoreSettingsData');
    final response =
        await _iapApi.getProfileData(_requester, _filename, _version);
    final data = SettingsDataBackup.fromJson(json.decode(response));
    await _configurationService
        .setImmediatePlaybackEnabled(data.immediatePlaybacks);

    _configurationService.setAnalyticEnabled(data.isAnalyticsEnabled);
    if (data.uxGuideStep != null) {
      await _configurationService.setUXGuideStep(data.uxGuideStep!);
    }

    await _configurationService.setFinishedSurvey(data.finishedSurveys);

    await _configurationService.updateTempStorageHiddenTokenIDs(
        data.hiddenMainnetTokenIDs, true,
        network: Network.MAINNET, override: true);
    await _configurationService.updateTempStorageHiddenTokenIDs(
        data.hiddenTestnetTokenIDs, true,
        network: Network.TESTNET, override: true);

    await _configurationService.setHidePersonaInGallery(
        data.hiddenFullAccountsFromGallery, true,
        override: true);

    await _configurationService.setHideLinkedAccountInGallery(
        data.hiddenLinkedAccountsFromGallery, true,
        override: true);

    log.info('[SettingsDataService][Done] restoreSettingsData');
  }
}

@JsonSerializable()
class SettingsDataBackup {
  bool immediatePlaybacks;
  bool isAnalyticsEnabled;
  int? uxGuideStep;
  List<String> finishedSurveys;
  List<String> hiddenMainnetTokenIDs;
  List<String> hiddenTestnetTokenIDs;
  List<String> hiddenFullAccountsFromGallery;
  List<String> hiddenLinkedAccountsFromGallery;

  SettingsDataBackup({
    required this.immediatePlaybacks,
    required this.isAnalyticsEnabled,
    required this.uxGuideStep,
    required this.finishedSurveys,
    required this.hiddenMainnetTokenIDs,
    required this.hiddenTestnetTokenIDs,
    required this.hiddenFullAccountsFromGallery,
    required this.hiddenLinkedAccountsFromGallery,
  });

  factory SettingsDataBackup.fromJson(Map<String, dynamic> json) =>
      _$SettingsDataBackupFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsDataBackupToJson(this);
}
