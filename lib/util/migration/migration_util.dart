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
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';
import 'package:nft_collection/services/address_service.dart' as ads;

class MigrationUtil {
  static const MethodChannel _channel = MethodChannel('migration_util');
  final CloudDatabase _cloudDB;
  final AuditService _auditService;
  final ads.AddressService _collectionAddressService =
      injector<ads.AddressService>();
  final AddressService _addressService = injector<AddressService>();
  final int requiredAndroidMigrationVersion = 95;

  MigrationUtil(this._cloudDB, this._auditService);

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

    final primaryAddressInfo = await _addressService.getPrimaryAddressInfo();
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
        final defaultAccount = primaryAddressInfo?.uuid == uuid ? 1 : 0;

        final persona = Persona.newPersona(
            uuid: uuid,
            name: name,
            createdAt: DateTime.now(),
            defaultAccount: defaultAccount);

        await _cloudDB.personaDao.insertPersona(persona);
        await _auditService.auditPersonaAction(
            '[_migrationkeychain] insert', persona);
      }
    }

    //Cleanup broken personas
    final currentPersonas = await _cloudDB.personaDao.getPersonas();
    for (var persona in currentPersonas) {
      if (!(await persona.wallet().isWalletCreated())) {
        final addresses =
            await _cloudDB.addressDao.getAddressesByPersona(persona.uuid);
        await _collectionAddressService
            .deleteAddresses(addresses.map((e) => e.address).toList());
        await _cloudDB.addressDao.deleteAddressesByPersona(persona.uuid);
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
