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

  Future<ShardDeck> requestDeckFromShardService(String domain, String otp);
  Future restoreAccount(ShardDeck ecShardDeck);
  Future clearRestoreProcess();

  Future<List<ContactDeck>> getContactDecks();
  Future storeContactDeck(ContactDeck contactDeck);

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

    final account = await _accountService.getCurrentDefaultAccount();
    if (account == null) return;

    if (await account.getShard(ShardType.Platform) == null) {
      // Has not setupSSKR or LostPlatform
      socialRecoveryStep.value = _configurationService.isLostPlatformRestore()
          ? SocialRecoveryStep.RestartWhenLostPlatform
          : SocialRecoveryStep.SetupShardService;
    } else {
      // has setupSSKR

      // setupSSKR but hasn't done to send ShardDeck to ShardService
      if (await account.getShard(ShardType.ShardService) != null) {
        socialRecoveryStep.value = SocialRecoveryStep.SetupShardService;
      } else {
        // Check history to see if user deleted/added accounts after setupSSKR
        final lastAudit = (await _cloudDB.auditDao.getAuditsByCategoryActions(
          [
            'create',
            'import',
            'delete',
            '[androidRestoreKeys] insert',
            '[_migrationData] insert',
            '[_migrationkeychain] insert'
          ],
          ['setupSSKR'],
        ))
            .firstOrNull;

        if (lastAudit == null || lastAudit.action != 'setupSSKR') {
          socialRecoveryStep.value = SocialRecoveryStep.RestartWhenHasChanges;
        } else {
          if (await account.getShard(ShardType.EmergencyContact) != null) {
            // has not setup EmergencyContact
            socialRecoveryStep.value = SocialRecoveryStep.SetupEmergencyContact;
          } else {
            // has setup EmergencyContact
            socialRecoveryStep.value = SocialRecoveryStep.Done;
          }
        }
      }
    }
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

  Future<ShardDeck> requestDeckFromShardService(
      String domain, String otp) async {
    await Future.delayed(Duration(seconds: 4));

    final shardDeck = """
{"defaultAccount":{"uuid":"a59c2335-9202-4cc4-855a-3fb18e5d93d1","shard":"tuna acid epic gyro song easy able acid acid easy real real taco foxy kite door vial hard wasp pool numb ugly diet duty barn cats edge limp iris"},"otherAccounts":[{"uuid":"6f7c9a6b-067c-4939-bd6f-e17978c089a7","shard":"tuna acid epic gyro navy math able acid acid vast epic bald film brag purr paid game game jump mild zaps omit idea runs away main taxi good epic"},{"uuid":"3580d290-a275-4622-8fb5-ad18adeb1bc8","shard":"tuna acid epic gyro oboe gems able acid acid beta ruby down fizz days need peck kick crux work city zone draw item stub very easy vial easy easy"}]}
""";
    return ShardDeck.fromJson(jsonDecode(shardDeck));
  }

  Future restoreAccount(ShardDeck ecShardDeck) async {
    final shardServiceDeck =
        _configurationService.getCachedDeckFromShardService();
    if (shardServiceDeck == null) throw IncorrectFlow();

    // Restore Default Account
    final defaultAccountUUID = shardServiceDeck.defaultAccount.uuid;
    final defaultShares = [
      shardServiceDeck.defaultAccount.shard,
      ecShardDeck.defaultAccount.shard
    ];

    await LibAukDart.getWallet(defaultAccountUUID)
        .restoreByBytewordShards(defaultShares, name: "Default");

    // -- Restore other accounts
    Map<String, List<dynamic>> accountsInfo = {};
    final backupVersion = await _backupService
        .fetchBackupVersion(await _accountService.getDefaultAccount());

    if (backupVersion.isNotEmpty) {
      await _backupService.restoreCloudDatabase(
          await _accountService.getDefaultAccount(), backupVersion);
      await _accountService.androidRestoreKeys();

      // Get name and creationDate

      for (final persona in await _cloudDB.personaDao.getPersonas()) {
        accountsInfo[persona.uuid] = [persona.name, persona.createdAt];
      }
    }
    // Get shares from shardServiceDeck
    Map<String, String> accountsShares = {};
    for (final info in shardServiceDeck.otherAccounts) {
      accountsShares[info.uuid] = info.shard;
    }

    for (final info in ecShardDeck.otherAccounts) {
      final share1 = accountsShares[info.uuid];
      if (share1 == null) continue;

      final shares = [share1, info.shard];
      final accountInfo = accountsInfo[info.uuid];

      await LibAukDart.getWallet(info.uuid).restoreByBytewordShards(
        shares,
        name: accountInfo?[0],
        creationDate: accountInfo?[1],
      );
    }

    //
    await _configurationService.setIsLostPlatformRestore(true);
    await _configurationService.setCachedDeckFromShardService(null);
  }

  Future clearRestoreProcess() async {
    await _configurationService.setCachedDeckFromShardService(null);
  }

  Future<List<ContactDeck>> getContactDecks() async {
    return await _socialRecoveryChannel.getContactDecks();
  }

  Future storeContactDeck(ContactDeck contactDeck) async {
    return _socialRecoveryChannel.storeContactDeck(contactDeck);
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
