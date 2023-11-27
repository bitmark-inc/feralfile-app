//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:flutter/services.dart';
import 'package:nft_collection/services/address_service.dart';

class MigrationUtil {
  static const MethodChannel _channel = MethodChannel('migration_util');
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final IAPService _iapService;
  final AuditService _auditService;
  final int requiredAndroidMigrationVersion = 95;

  MigrationUtil(
    this._configurationService,
    this._cloudDB,
    this._iapService,
    this._auditService,
  );

  Future<void> migrateIfNeeded() async {
    if ((await _cloudDB.personaDao.getDefaultPersonas()).isNotEmpty) {
      unawaited(_iapService.restore());
    }
    await _migrateViewOnlyAddresses();
    log.info('[migration] finished');
  }

  Future<void> _migrateViewOnlyAddresses() async {
    if (_configurationService.getDidMigrateAddress()) {
      return;
    }

    final manualConnections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.manuallyAddress.rawValue);
    final needChecksumConnections = manualConnections
        .where((element) => element.key != _tryChecksum(element.key))
        .toList();

    if (needChecksumConnections.isNotEmpty) {
      final addressService = injector<AddressService>();
      final checksumConnections = needChecksumConnections.map((e) {
        final checksumAddress = _tryChecksum(e.key);
        return e.copyWith(key: checksumAddress, accountNumber: checksumAddress);
      }).toList();
      final personaAddresses =
          (await _cloudDB.addressDao.getAddressesByType(CryptoType.ETH.source))
              .map((e) => e.address);
      final connectionAddresses = manualConnections.map((e) => e.key);
      checksumConnections.removeWhere((element) =>
          personaAddresses.contains(element.key) ||
          connectionAddresses.contains(element.key));
      await _cloudDB.connectionDao.deleteConnections(needChecksumConnections);
      await addressService
          .deleteAddresses(needChecksumConnections.map((e) => e.key).toList());
      await _cloudDB.connectionDao.insertConnections(checksumConnections);
      await addressService
          .addAddresses(checksumConnections.map((e) => e.key).toList());
    }

    unawaited(_configurationService.setDidMigrateAddress(true));
  }

  String _tryChecksum(String address) {
    try {
      return address.getETHEip55Address();
    } catch (_) {
      return address;
    }
  }

  Future<void> migrationFromKeychain() async {
    if (!Platform.isIOS) {
      return;
    }
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
        '[_migrationFromKeychain] personaUUIDs from Keychain: $personaUUIDs');
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

        // final backupVersion =
        // await _backupService.fetchBackupVersion(wallet);
        // final defaultAccount = backupVersion.isNotEmpty ? 1 : null;

        final persona = Persona.newPersona(
            uuid: uuid,
            name: name,
            createdAt: DateTime.now(),
            defaultAccount: 1);

        await _cloudDB.personaDao.insertPersona(persona);
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
      final String? deviceId = await _channel.invokeMethod('getDeviceID', {});

      return deviceId ?? await getDeviceID();
    } else {
      return await getDeviceID();
    }
  }
}
