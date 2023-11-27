//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'settings_data_service.g.dart';

abstract class SettingsDataService {
  Future backup();

  Future firestoreBackup();

  Future restoreSettingsData();

  Future restoreSettingsDataFromFirestore();
}

class SettingsDataServiceImpl implements SettingsDataService {
  final ConfigurationService _configurationService;
  final AccountService _accountService;
  final IAPApi _iapApi;
  final CloudDatabase _cloudDB;
  final CloudFirestoreService _cloudFirestoreService;

  var latestDataHash = '';

  SettingsDataServiceImpl(
    this._configurationService,
    this._accountService,
    this._iapApi,
    this._cloudDB,
    this._cloudFirestoreService,
  );

  final _requester =
      'requester'; // server ignore this when putting jwt, so just put something
  final _filename = 'settings_data_backup.json';
  final _version = '1';
  var _numberOfCallingBackups = 0;

  Future<SettingsDataBackup> _getSettingsDataBackup() async {
    final addresses = await _accountService.getShowedAddresses();
    final hiddenMainnetTokenIDs =
        _configurationService.getTempStorageHiddenTokenIDs();
    final hiddenAddressesFromGallery =
        (await _cloudDB.addressDao.findAddressesWithHiddenStatus(true))
            .map((e) => e.address)
            .toList();
    final hiddenLinkedAccountsFromGallery =
        _configurationService.getLinkedAccountsHiddenInGallery();
    final playlists = _configurationService.getPlayList();

    return SettingsDataBackup(
      addresses: addresses,
      isAnalyticsEnabled: _configurationService.isAnalyticsEnabled(),
      hiddenMainnetTokenIDs: hiddenMainnetTokenIDs,
      hiddenTestnetTokenIDs: [],
      hiddenAddressesFromGallery: hiddenAddressesFromGallery,
      hiddenLinkedAccountsFromGallery: hiddenLinkedAccountsFromGallery,
      playlists: playlists,
    );
  }

  @override
  Future backup() async {
    await firestoreBackup();
    log.info('[SettingsDataService][Start] backup');

    final data = await _getSettingsDataBackup();

    final dataBytes = utf8.encode(json.encode(data.toJson()));
    final dataHash = sha512.convert(dataBytes).toString();
    if (latestDataHash == dataHash) {
      log.info("[SettingsDataService] skip backup because of it's identical");
      return;
    }

    String dir = (await getTemporaryDirectory()).path;
    File backupFile = File('$dir/$_filename');
    await backupFile.writeAsBytes(dataBytes, flush: true);

    var isSuccess = false;
    while (!isSuccess) {
      try {
        await _iapApi.uploadProfile(
            _requester, _filename, _version, backupFile);
        isSuccess = true;
      } catch (exception) {
        Sentry.captureException(exception);
      }
    }

    latestDataHash = dataHash;

    if (_numberOfCallingBackups == 1) {
      backupFile.delete();
    }

    _numberOfCallingBackups -= 1;

    log.info('[SettingsDataService][Done] backup');
  }

  @override
  Future firestoreBackup() async {
    final data = await _getSettingsDataBackup();
    final collection = _cloudFirestoreService
        .getCollection('settings_data')
        .withConverter<SettingsDataBackup>(
            fromFirestore: (snapshot, _) =>
                SettingsDataBackup.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson());
    await collection.doc(collection.id).set(data);
  }

  @override
  Future restoreSettingsData() async {
    await restoreSettingsDataFromFirestore();
    return;
    log.info('[SettingsDataService][Start] restoreSettingsData');
    final response =
        await _iapApi.getProfileData(_requester, _filename, _version);
    final data = SettingsDataBackup.fromJson(json.decode(response));

    _configurationService.setAnalyticEnabled(data.isAnalyticsEnabled);

    await _configurationService.updateTempStorageHiddenTokenIDs(
        data.hiddenMainnetTokenIDs, true,
        override: true);

    await Future.wait((data.hiddenAddressesFromGallery ?? [])
        .map((e) => _cloudDB.addressDao.setAddressIsHidden(e, true)));

    await _configurationService.setHideLinkedAccountInGallery(
        data.hiddenLinkedAccountsFromGallery, true,
        override: true);

    await _configurationService.setPlayList(data.playlists, override: true);

    log.info('[SettingsDataService][Done] restoreSettingsData');
  }

  @override
  Future restoreSettingsDataFromFirestore() {
    final collection = _cloudFirestoreService
        .getCollection('settings_data')
        .withConverter<SettingsDataBackup>(
            fromFirestore: (snapshot, _) =>
                SettingsDataBackup.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson());
    return collection.doc(collection.id).get().then((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        await _configurationService.setAnalyticEnabled(data.isAnalyticsEnabled);

        await _configurationService.updateTempStorageHiddenTokenIDs(
            data.hiddenMainnetTokenIDs, true,
            override: true);

        await Future.wait((data.hiddenAddressesFromGallery ?? [])
            .map((e) => _cloudDB.addressDao.setAddressIsHidden(e, true)));

        await _configurationService.setHideLinkedAccountInGallery(
            data.hiddenLinkedAccountsFromGallery, true,
            override: true);

        await _configurationService.setPlayList(data.playlists, override: true);
      }
    });
  }
}

@JsonSerializable()
class SettingsDataBackup {
  List<String> addresses;
  bool isAnalyticsEnabled;
  List<String> hiddenMainnetTokenIDs;
  List<String> hiddenTestnetTokenIDs;
  List<String> hiddenLinkedAccountsFromGallery;
  List<String>? hiddenAddressesFromGallery;
  List<PlayListModel> playlists;

  SettingsDataBackup({
    required this.addresses,
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
