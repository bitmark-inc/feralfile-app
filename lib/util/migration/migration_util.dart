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
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_data.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MigrationUtil {
  static const MethodChannel _channel = MethodChannel('migration_util');
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final AccountService _accountService;
  final IAPService _iapService;
  final AuditService _auditService;
  final BackupService _backupService;
  final int requiredAndroidMigrationVersion = 95;

  MigrationUtil(this._configurationService, this._cloudDB, this._accountService,
      this._iapService, this._auditService, this._backupService);

  Future<void> migrateIfNeeded() async {
    if (Platform.isIOS) {
      await _migrationiOS();
    } else {
      await _migrationAndroid();
    }

    if ((await _cloudDB.personaDao.getDefaultPersonas()).isNotEmpty) {
      _iapService.restore();
    }

    log.info("[migration] finished");
  }

  Future<void> migrationFromKeychain() async {
    if (!Platform.isIOS) return;
    final List personaUUIDs =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});

    final personas = await _cloudDB.personaDao.getPersonas();
    if (personas.length == personaUUIDs.length &&
        personas.every(
            (element) => personaUUIDs.contains(element.uuid.toUpperCase()))) {
      //Database is up-to-date, skip migrating
      return;
    }

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
        await persona.insertAddress(WalletType.Autonomy, name: persona.name);
        await _auditService.auditPersonaAction(
            '[_migrationkeychain] insert', persona);
      }
    }

    //Cleanup broken personas
    final currentPersonas = await _cloudDB.personaDao.getPersonas();
    for (var persona in currentPersonas) {
      if (!(await persona.wallet().isWalletCreated())) {
        await _cloudDB.personaDao.deletePersona(persona);
      }
    }
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
        final address = await wallet.getETHEip55Address();

        if (address.isEmpty) continue;
        final name = await wallet.getName();

        final persona =
            Persona(uuid: uuid, name: name, createdAt: mPersona.createdAt);

        await _cloudDB.personaDao.insertPersona(persona);
        await _auditService.auditPersonaAction(
            '[_migrationData] insert', persona);
      }
    }

    //Cleanup deleted or broken personas
    final currentPersonas = await _cloudDB.personaDao.getPersonas();
    for (final persona in currentPersonas) {
      if (!(await persona.wallet().isWalletCreated())) {
        await _cloudDB.personaDao.deletePersona(persona);
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
    final packageInfo = await PackageInfo.fromPlatform();
    _configurationService.setPreviousBuildNumber(packageInfo.buildNumber);
    if (previousBuildNumber == null) return;
    final previousBuildNumberInt = int.tryParse(previousBuildNumber);
    if (previousBuildNumberInt == null) return;

    if (previousBuildNumberInt < requiredAndroidMigrationVersion) {
      final packageInfo = await PackageInfo.fromPlatform();
      _configurationService.setPreviousBuildNumber(packageInfo.buildNumber);
      _accountService.androidBackupKeys();
    }
  }
}
