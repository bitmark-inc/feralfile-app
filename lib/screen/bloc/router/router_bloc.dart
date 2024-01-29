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
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'router_state.dart';

class RouterBloc extends AuBloc<RouterEvent, RouterState> {
  final ConfigurationService _configurationService;
  final BackupService _backupService;
  final AccountService _accountService;
  final CloudDatabase _cloudDB;
  final IAPService _iapService;
  final AuditService _auditService;
  final SettingsDataService _settingsDataService;

  Future<bool> hasAccounts() async {
    final personas = await _cloudDB.personaDao.getPersonas();
    final connections = await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    return personas.isNotEmpty || connections.isNotEmpty;
  }

  RouterBloc(
      this._configurationService,
      this._backupService,
      this._accountService,
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

      if (_configurationService.isDoneOnboarding()) {
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        return;
      }

      //Soft delay 1s waiting for database synchronizing
      await Future.delayed(const Duration(seconds: 1));

      if (await hasAccounts()) {
        unawaited(_configurationService.setOldUser());
        final backupVersion = await _backupService
            .fetchBackupVersion(await _accountService.getDefaultAccount());

        if (backupVersion.isNotEmpty) {
          log.info('[DefineViewRoutingEvent] have backup version');
          //restore backup database
          emit(RouterState(
              onboardingStep: OnboardingStep.restore,
              backupVersion: backupVersion));
          add(RestoreCloudDatabaseRoutingEvent(backupVersion));
          return;
        } else {
          await _configurationService.setDoneOnboarding(true);
          unawaited(injector<MetricClientService>()
              .mixPanelClient
              .initIfDefaultAccount());
          emit(RouterState(onboardingStep: OnboardingStep.dashboard));
          return;
        }
      } else {
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      }
    });

    on<RestoreCloudDatabaseRoutingEvent>((event, emit) async {
      try {
        if (_configurationService.isDoneOnboarding()) {
          return;
        }
        await _backupService.restoreCloudDatabase(
            await _accountService.getDefaultAccount(), event.version);

        await _settingsDataService.restoreSettingsData();

        await _accountService.androidRestoreKeys();

        final personas = await _cloudDB.personaDao.getPersonas();
        for (var persona in personas) {
          if (persona.name != '') {
            unawaited(persona.wallet().updateName(persona.name));
          }
        }
        final connections =
            await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
        if (personas.isEmpty && connections.isEmpty) {
          await _configurationService.setDoneOnboarding(false);
          emit(RouterState(onboardingStep: OnboardingStep.startScreen));
        } else {
          await _configurationService.setOldUser();
          if (_configurationService.isDoneOnboarding()) {
            return;
          }
          await _configurationService.setDoneOnboarding(true);
          unawaited(injector<MetricClientService>()
              .mixPanelClient
              .initIfDefaultAccount());
          emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        }
        await migrationUtil.migrateIfNeeded();
        unawaited(injector<MetricClientService>()
            .addEvent(MixpanelEvent.restoreAccount));
      } catch (e, stacktrace) {
        await Sentry.captureException(e, stackTrace: stacktrace);
        rethrow;
      }
    });
  }
}
