import 'dart:io';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/account_service.dart';
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
      this._iapService)
      : super(RouterState(onboardingStep: OnboardingStep.undefined)) {
    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) return;

      await MigrationUtil(_configurationService, _cloudDB, _accountService,
          _navigationService, _iapService)
          .migrateIfNeeded();

      if (_configurationService.isDoneOnboarding()) {
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
        return;
      }

      // Check and restore full accounts from cloud if existing
      await MigrationUtil(_configurationService, _cloudDB, _accountService,
          _navigationService, _iapService)
          .migrationFromKeychain(Platform.isIOS);
      await _accountService.androidRestoreKeys();

      //Soft delay 1s waiting for database synchronizing
      await Future.delayed(Duration(seconds: 1));

      if (await hasAccounts()) {
        final backupVersion = await _backupService.fetchBackupVersion();
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
              _navigationService, _iapService)
          .migrateIfNeeded();
    });
  }
}
