//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/util/migration/migration_data.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MigrationUtil {
  static const MethodChannel _channel = const MethodChannel('migration_util');
  ConfigurationService _configurationService;
  CloudDatabase _cloudDB;
  AccountService _accountService;
  NavigationService _navigationService;
  IAPService _iapService;
  AuditService _auditService;
  BackupService _backupService;
  FeralFileService _feralFileService;

  MigrationUtil(
      this._configurationService,
      this._cloudDB,
      this._accountService,
      this._navigationService,
      this._iapService,
      this._auditService,
      this._backupService,
      this._feralFileService);

  Future<void> migrateIfNeeded() async {
    if (Platform.isIOS) {
      await _migrationiOS();
    } else {
      await _migrationAndroid();
    }

    await _migrateFFConnection();

    _iapService.restore();
    log.info("[migration] finished");
  }

  Future<void> migrationFromKeychain(bool isIOS) async {
    if (isIOS) {
      await _migrationFromKeychain();
    }
    // TODO: support scan keys in Android when it's doable
  }

  static Future<String?> getBackupDeviceID() async {
    if (Platform.isIOS) {
      final String? deviceId = await _channel.invokeMethod("getDeviceID", {});

      return deviceId ?? await getDeviceID();
    } else {
      return await getDeviceID();
    }
  }

  Future _migrationiOS() async {
    log.info('[_migrationiOS] start');
    final String jsonString =
        await _channel.invokeMethod('getiOSMigrationData', {});
    if (jsonString.isEmpty) return;

    log.info('[_migrationiOS] get jsonString $jsonString');

    final jsonData = json.decode(jsonString);
    final migrationData = MigrationData.fromJson(jsonData);

    for (var mPersona in migrationData.personas) {
      final uuid = mPersona.uuid.toLowerCase();
      final existingPersona = await _cloudDB.personaDao.findById(uuid);
      if (existingPersona == null) {
        final wallet = Persona.newPersona(uuid: uuid).wallet();
        final address = await wallet.getETHAddress();

        if (address.isEmpty) continue;
        final name = await wallet.getName();

        final persona =
            Persona(uuid: uuid, name: name, createdAt: mPersona.createdAt);

        await _cloudDB.personaDao.insertPersona(persona);
        await _auditService.audiPersonaAction(
            '[_migrationData] insert', persona);
      }
    }

    for (var con in migrationData.ffTokenConnections) {
      final ffConnection =
          FeralFileConnection(source: con.source, ffAccount: con.ffAccount);
      final connection = Connection(
        key: con.token,
        name: con.ffAccount.alias,
        data: json.encode(ffConnection),
        connectionType: ConnectionType.feralFileToken.rawValue,
        accountNumber: con.ffAccount.id,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.ffWeb3Connections) {
      final ffWeb3Connection = FeralFileWeb3Connection(
          personaAddress: con.address,
          source: con.source,
          ffAccount: con.ffAccount);
      final connection = Connection(
        key: con.topic,
        name: con.ffAccount.alias,
        data: json.encode(ffWeb3Connection),
        connectionType: ConnectionType.feralFileWeb3.rawValue,
        accountNumber: con.ffAccount.id,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.walletBeaconConnections) {
      final connection = Connection(
        key: con.tezosWalletConnection.address,
        name: con.name,
        data: json.encode(con.tezosWalletConnection),
        connectionType: ConnectionType.walletBeacon.rawValue,
        accountNumber: con.tezosWalletConnection.address,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.walletConnectConnections) {
      if (con.wcConnectedSession.accounts.isEmpty) continue;
      final connection = Connection(
        key: con.wcConnectedSession.accounts.first,
        name: con.name,
        data: json.encode(con.wcConnectedSession),
        connectionType: ConnectionType.walletConnect.rawValue,
        accountNumber: con.wcConnectedSession.accounts.first,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    await _channel.invokeMethod("cleariOSMigrationData", {});
    log.info('[_migrationIOS] Done');
  }

  Future _migrationAndroid() async {
    final previousBuildNumber = _configurationService.getPreviousBuildNumber();

    if (previousBuildNumber == null) {
      final packageInfo = await PackageInfo.fromPlatform();
      _configurationService.setPreviousBuildNumber(packageInfo.buildNumber);
      _accountService.androidBackupKeys();
    }
  }

  Future _migrationFromKeychain() async {
    final List personaUUIDs =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});

    log.info(
        "[_migrationFromKeychain] personaUUIDs from Keychain: $personaUUIDs");
    for (var personaUUID in personaUUIDs) {
      //Cleanup duplicated persona
      final oldPersona = await _cloudDB.personaDao.findById(personaUUID);
      if (oldPersona != null) {
        await _cloudDB.personaDao.deletePersona(oldPersona);
      }

      final uuid = personaUUID.toLowerCase();
      final existingPersona = await _cloudDB.personaDao.findById(uuid);
      if (existingPersona == null) {
        final wallet = Persona.newPersona(uuid: uuid).wallet();
        final name = await wallet.getName();

        final backupVersion = await _backupService.fetchBackupVersion(wallet);
        final defaultAccount = backupVersion.isNotEmpty ? 1 : null;

        final persona = Persona.newPersona(
            uuid: uuid,
            name: name,
            createdAt: DateTime.now(),
            defaultAccount: defaultAccount);

        await _cloudDB.personaDao.insertPersona(persona);
        await _auditService.audiPersonaAction(
            '[_migrationkeychain] insert', persona);
      }
    }
  }

  Future _migrateFFConnection() async {
    for (var con in await _cloudDB.connectionDao.getConnections()) {
      if (con.connectionType != ConnectionType.feralFileToken.rawValue) {
        return;
      }

      if (con.ffConnection != null) {
        return;
      }

      final ffAccount = await _feralFileService.getAccount(con.key);
      final network = _configurationService.getNetwork();
      final source = network == Network.MAINNET
          ? "https://feralfile.com"
          : "https://feralfile1.dev.bitmark.com";

      final ffConnection = Connection.fromFFToken(con.key, source, ffAccount);

      await _cloudDB.connectionDao.updateConnection(ffConnection);
    }
  }
}
