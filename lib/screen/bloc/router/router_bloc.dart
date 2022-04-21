import 'dart:io';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:bloc/bloc.dart';

part 'router_state.dart';

class RouterBloc extends Bloc<RouterEvent, RouterState> {
  ConfigurationService _configurationService;
  BackupService _backupService;
  AccountService _accountService;
  CloudDatabase _cloudDB;
  NavigationService _navigationService;
  IAPService _iapService;
  AuditService _auditService;

  Future<bool> hasAccounts() async {
    final personas = await _cloudDB.personaDao.getPersonas();
    final connections = await _cloudDB.connectionDao.getLinkedAccounts();
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
    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) return;

      await MigrationUtil(_configurationService, _cloudDB, _accountService,
              _navigationService, _iapService, _auditService)
          .migrateIfNeeded();
      if (await hasAccounts()) {
        _configurationService.setDoneOnboarding(true);
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
      } else {
        final backupVersion = await _backupService.fetchBackupVersion();
        if (backupVersion.isNotEmpty) {
          log.info("[DefineViewRoutingEvent] have backup version");
          //restore backup database
          emit(RouterState(
              onboardingStep: OnboardingStep.restore,
              backupVersion: backupVersion));
          return;
        } else {
          // has no backup file; try to migration from Keychain
          await MigrationUtil(_configurationService, _cloudDB, _accountService,
                  _navigationService, _iapService, _auditService)
              .migrationFromKeychain(Platform.isIOS);
          await _accountService.androidRestoreKeys();

          if (await hasAccounts()) {
            _configurationService.setDoneOnboarding(true);
            emit(RouterState(onboardingStep: OnboardingStep.dashboard));
            return;
          }
        }

        _configurationService.setDoneOnboarding(false);

        if (_configurationService.isDoneOnboardingOnce()) {
          emit(RouterState(onboardingStep: OnboardingStep.newAccountPage));
        } else {
          emit(RouterState(onboardingStep: OnboardingStep.startScreen));
        }
      }
    });

    on<RestoreCloudDatabaseRoutingEvent>((event, emit) async {
      emit(RouterState(
          onboardingStep: state.onboardingStep,
          backupVersion: state.backupVersion,
          isLoading: true));

      await _backupService.restoreCloudDatabase(event.version);
      await _accountService.androidRestoreKeys();

      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();
      if (personas.isEmpty && connections.isEmpty) {
        _configurationService.setDoneOnboarding(false);
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      } else {
        _configurationService.setDoneOnboarding(true);
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
      }
      await MigrationUtil(_configurationService, _cloudDB, _accountService,
              _navigationService, _iapService, _auditService)
          .migrateIfNeeded();
    });
  }
}
