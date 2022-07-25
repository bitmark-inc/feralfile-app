//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';

part 'router_state.dart';

class RouterBloc extends AuBloc<RouterEvent, RouterState> {
  ConfigurationService _configurationService;
  BackupService _backupService;
  AccountService _accountService;
  CloudDatabase _cloudDB;
  NavigationService _navigationService;
  IAPService _iapService;
  AuditService _auditService;

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
      this._navigationService,
      this._iapService,
      this._auditService)
      : super(RouterState(onboardingStep: OnboardingStep.undefined)) {
    final migrationUtil = MigrationUtil(
        _configurationService,
        _cloudDB,
        _accountService,
        _navigationService,
        _iapService,
        _auditService,
        _backupService);

    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) return;

      await migrationUtil.migrateIfNeeded();

      // Check and restore full accounts from cloud if existing
      await migrationUtil.migrationFromKeychain(Platform.isIOS);
      await _accountService.androidRestoreKeys();

      if (_configurationService.isDoneOnboarding()) {
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        return;
      }

      //Soft delay 1s waiting for database synchronizing
      await Future.delayed(Duration(seconds: 1));

      if (await hasAccounts()) {
        final backupVersion = await _backupService
            .fetchBackupVersion(await _accountService.getDefaultAccount());

        await injector<AWSService>().initServices();

        if (backupVersion.isNotEmpty) {
          log.info("[DefineViewRoutingEvent] have backup version");
          //restore backup database
          emit(RouterState(
              onboardingStep: OnboardingStep.restore,
              backupVersion: backupVersion));
          return;
        } else {
          _configurationService.setDoneOnboarding(true);
          emit(RouterState(onboardingStep: OnboardingStep.dashboard));
          return;
        }
      } else {
        if (_configurationService.getCachedDeckFromShardService() == null) {
          emit(RouterState(onboardingStep: OnboardingStep.startScreen));
          //
        } else {
          // user's in process restoring account with social recovery
          emit(RouterState(
              onboardingStep: OnboardingStep.restoreWithEmergencyContact));
        }
      }
    });

    on<RestoreCloudDatabaseRoutingEvent>((event, emit) async {
      emit(RouterState(
          onboardingStep: state.onboardingStep,
          backupVersion: state.backupVersion,
          isLoading: true));

      await _backupService.restoreCloudDatabase(
          await _accountService.getDefaultAccount(), event.version);
      await _accountService.androidRestoreKeys();

      final personas = await _cloudDB.personaDao.getPersonas();
      final connections =
          await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      if (personas.isEmpty && connections.isEmpty) {
        _configurationService.setDoneOnboarding(false);
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      } else {
        _configurationService.setDoneOnboarding(true);
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
      }
      await migrationUtil.migrateIfNeeded();
    });
  }
}
