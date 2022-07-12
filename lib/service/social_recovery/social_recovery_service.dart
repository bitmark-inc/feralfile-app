//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/social_recovery_channel.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:libauk_dart/libauk_dart.dart';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum SocialRecoveryStep {
  SetupShardService,
  SetupEmergencyContact,
  Done,
  RestartWhenHasChanges,
  RestartWhenLostPlatform,
}

abstract class SocialRecoveryService {
  ValueNotifier<SocialRecoveryStep?> get socialRecoveryStep;
  Future refreshSetupStep();
  Future sendDeckToShardService(String domain, String otp);
  Future<String> getEmergencyContactDeck();
  Future doneSetupEmergencyContact();

  Future<String> storeDataInTempSecretFile(String data);
  Future cleanTempSecretFile();
}

class SocialRecoveryServiceImpl extends SocialRecoveryService {
  ValueNotifier<SocialRecoveryStep?> socialRecoveryStep = ValueNotifier(null);

  late SocialRecoveryChannel _socialRecoveryChannel;
  CloudDatabase _cloudDB;
  AccountService _accountService;
  AuditService _auditService;
  ConfigurationService _configurationService;
  BackupService _backupService;

  SocialRecoveryServiceImpl(
    this._cloudDB,
    this._accountService,
    this._auditService,
    this._configurationService,
    this._backupService,
  ) {
    _socialRecoveryChannel = SocialRecoveryChannel();
    refreshSetupStep();
  }

  Future refreshSetupStep() async {
    // NOTE: Update this when support Social Recovery in Android
    if (!Platform.isIOS) return;
  }

  Future sendDeckToShardService(String domain, String otp) async {
    final accounts = await _cloudDB.personaDao.getPersonas();

    // generate SSKR
    for (final account in accounts) {
      final wallet = LibAukDart.getWallet(account.uuid);
      await wallet.setupSSKR();
    }

    // Create ShardService's ShardDeck
    final shardDeck = await _createShardDeck(accounts, ShardType.ShardService);

    // Send to ShardService with OTP
    print("THUYEN ${jsonEncode(shardDeck)}");
    await Future.delayed(Duration(seconds: 4));

    // Done
    await _removeShards(accounts, ShardType.ShardService);
    await _auditService.auditSocialRecoveryAction('setupSSKR');
    socialRecoveryStep.value = SocialRecoveryStep.SetupEmergencyContact;
  }

  Future<String> getEmergencyContactDeck() async {
    final accounts = await _cloudDB.personaDao.getPersonas();

    final shardDeck =
        await _createShardDeck(accounts, ShardType.EmergencyContact);
    return storeDataInTempSecretFile(jsonEncode(shardDeck));
  }

  Future doneSetupEmergencyContact() async {
    final accounts = await _cloudDB.personaDao.getPersonas();

    await _removeShards(accounts, ShardType.EmergencyContact);
    socialRecoveryStep.value = SocialRecoveryStep.Done;
    await _auditService.auditSocialRecoveryAction('Done');
  }

  Future<String> storeDataInTempSecretFile(String data) async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${appDocumentsDirectory.path}/social-recovery/secret.json';

    File file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(utf8.encode(data));

    return filePath;
  }

  Future cleanTempSecretFile() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${appDocumentsDirectory.path}/social-recovery/secret.json';
    File file = File(filePath);
    if (await file.exists()) {
      file.delete();
    }
  }

  Future<ShardDeck> _createShardDeck(
      List<Persona> accounts, ShardType shardType) async {
    ShardInfo? defaultAccount;
    List<ShardInfo> otherAccounts = [];

    for (final account in accounts) {
      String? shard;
      switch (shardType) {
        case ShardType.ShardService:
          shard = await LibAukDart.getWallet(account.uuid)
              .getShard(ShardType.ShardService);
          break;

        case ShardType.EmergencyContact:
          shard = await LibAukDart.getWallet(account.uuid)
              .getShard(ShardType.EmergencyContact);
          break;
        case ShardType.Platform:
          // do nothing
          break;
      }

      if (shard == null) throw SocialRecoveryMissingShard();
      if (account.defaultAccount == 1) {
        defaultAccount = ShardInfo(uuid: account.uuid, shard: shard);
      } else {
        otherAccounts.add(ShardInfo(uuid: account.uuid, shard: shard));
      }
    }

    if (defaultAccount == null) throw SocialRecoveryMissingShard();
    return ShardDeck(
      defaultAccount: defaultAccount,
      otherAccounts: otherAccounts,
    );
  }

  Future _removeShards(List<Persona> accounts, ShardType shardType) async {
    switch (shardType) {
      case ShardType.ShardService:
        for (final account in accounts) {
          await LibAukDart.getWallet(account.uuid)
              .removeShard(ShardType.ShardService);
        }
        break;

      case ShardType.EmergencyContact:
        for (final account in accounts) {
          await LibAukDart.getWallet(account.uuid)
              .removeShard(ShardType.EmergencyContact);
        }
        break;
      case ShardType.Platform:
        break;
    }
  }
}
