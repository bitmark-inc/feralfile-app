//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'router_state.dart';

class RouterBloc extends AuBloc<RouterEvent, RouterState> {
  final ConfigurationService _configurationService;
  final BackupService _backupService;
  final AccountService _accountService;
  final AddressService _addressService;
  final CloudDatabase _cloudDB;
  final IAPService _iapService;
  final AuditService _auditService;
  final SettingsDataService _settingsDataService;

  Future<bool> _hasAccounts() async {
    final personas = await _cloudDB.personaDao.getPersonas();
    final connections = await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    return personas.isNotEmpty || connections.isNotEmpty;
  }

  RouterBloc(
      this._configurationService,
      this._backupService,
      this._accountService,
      this._addressService,
      this._cloudDB,
      this._iapService,
      this._auditService,
      this._settingsDataService)
      : super(RouterState(onboardingStep: OnboardingStep.undefined)) {
    final migrationUtil = MigrationUtil(_configurationService, _cloudDB,
        _accountService, _iapService, _auditService, _backupService);

    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) {
        return;
      }

      await migrationUtil.migrateIfNeeded();

      // Check and restore full accounts from cloud if existing
      await migrationUtil.migrationFromKeychain();
      await _accountService.androidRestoreKeys();
      final hasAccount = await _hasAccounts();
      if (!hasAccount) {
        await _configurationService.setDoneOnboarding(hasAccount);
      }

      // migrate to membership profile
      final primaryAddressInfo = await _addressService.getPrimaryAddressInfo();

      if (_configurationService.isDoneOnboarding()) {
        if (primaryAddressInfo == null) {
          try {
            final addresses = await _addressService.getAllAddress();
            if (addresses.isEmpty) {
              await _addressService.deriveAddressesFromAllPersona();
            }
            final addressInfo = await _addressService.pickAddressAsPrimary();
            await _addressService.registerPrimaryAddress(
                info: addressInfo, withDidKey: true);
          } catch (e, stacktrace) {
            log.info('Error while picking primary address', e, stacktrace);
            // rethrow;
          }
        }

        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        return;
      }

      //Soft delay 1s waiting for database synchronizing
      await Future.delayed(const Duration(seconds: 1));

      // case not onboarding
      // 1. New user
      // 2. Old user with restore backup

      if (hasAccount) {
        // Old user
        // Do backup restore
        unawaited(_configurationService.setOldUser());

        // get backup version by primary address
        // if primary address is not exist, return empty
        final backupVersion = await _backupService.getBackupVersion();

        if (backupVersion.isNotEmpty) {
          log.info('[DefineViewRoutingEvent] have backup version');
          //restore backup database
          emit(RouterState(onboardingStep: OnboardingStep.restore));
          add(RestoreCloudDatabaseRoutingEvent());
          return;
        } else {
          // case old user without backup
          unawaited(injector<MetricClientService>()
              .mixPanelClient
              .initIfDefaultAccount());

          // for each persona, derive addresses from keychain
          // then derive primary address, if primary address exist
          await _addressService.deriveAddressesFromAllPersona();

          // if primary address is not exist, pick one and register as primary
          if (primaryAddressInfo == null) {
            final primaryAddressInfo =
                await _addressService.pickAddressAsPrimary();
            await _addressService.registerPrimaryAddress(
                info: primaryAddressInfo);
          }

          emit(RouterState(onboardingStep: OnboardingStep.dashboard));
          await _configurationService.setDoneOnboarding(true);
          return;
        }
      } else {
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      }
    });

    on<RestoreCloudDatabaseRoutingEvent>((event, emit) async {
      // restore backup database
      // now the primary address is exist
      // get cloud data by primary address using address JWT
      try {
        if (_configurationService.isDoneOnboarding()) {
          return;
        }
        log.info('[RestoreCloudDatabase] restoreCloudDatabase');
        await _backupService.restoreCloudDatabase();

        await _settingsDataService.restoreSettingsData();

        await _accountService.androidRestoreKeys();
        log.info('[RestoreCloudDatabase] restoreCloudDatabase success');

        final personas = await _cloudDB.personaDao.getPersonas();
        log.info('[RestoreCloudDatabase] personas: ${personas.length}');
        for (var persona in personas) {
          if (persona.name != '') {
            unawaited(persona.wallet().updateName(persona.name));
          }
        }
        final connections =
            await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
        log.info('[RestoreCloudDatabase] connections: ${connections.length}');
        await _configurationService.setOldUser();
        if (_configurationService.isDoneOnboarding()) {
          return;
        }
        unawaited(injector<MetricClientService>()
            .mixPanelClient
            .initIfDefaultAccount());
        await migrationUtil.migrateIfNeeded();
        try {
          final addresses = await _addressService.getAllAddress();
          if (addresses.isEmpty) {
            await _addressService.deriveAddressesFromAllPersona();
          }
          final addressInfo = await _addressService.pickAddressAsPrimary();
          await _addressService.registerPrimaryAddress(
              info: addressInfo, withDidKey: true);
        } catch (e, stacktrace) {
          log.info('Error while picking primary address', e, stacktrace);
          // rethrow;
        }
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        await _configurationService.setDoneOnboarding(true);
      } catch (e, stacktrace) {
        await Sentry.captureException(e, stackTrace: stacktrace);
        rethrow;
      }
    });
  }
}
