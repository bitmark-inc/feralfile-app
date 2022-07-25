//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ForgetExistBloc extends AuBloc<ForgetExistEvent, ForgetExistState> {
  AuthService _authService;
  AccountService _accountService;
  AutonomyService _autonomyService;
  IAPApi _iapApi;
  CloudDatabase _cloudDatabase;
  AppDatabase _mainnetDatabase;
  AppDatabase _testnetDatabase;
  ConfigurationService _configurationService;
  SocialRecoveryService _socialRecoveryService;

  ForgetExistBloc(
    this._authService,
    this._accountService,
    this._autonomyService,
    this._iapApi,
    this._cloudDatabase,
    this._mainnetDatabase,
    this._testnetDatabase,
    this._configurationService,
    this._socialRecoveryService,
  ) : super(ForgetExistState(false, null)) {
    on<UpdateCheckEvent>((event, emit) async {
      emit(ForgetExistState(event.isChecked, state.isProcessing));
    });

    on<ConfirmForgetExistEvent>((event, emit) async {
      emit(ForgetExistState(state.isChecked, true));

      deregisterPushNotification();
      await _autonomyService.clearLinkedAddresses();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String? deviceId = await MigrationUtil.getBackupDeviceID();
      final requester = "$deviceId\_${packageInfo.packageName}";
      await _iapApi.deleteAllProfiles(requester);
      await _iapApi.deleteUserData();

      final List<Persona> personas =
          await _cloudDatabase.personaDao.getPersonas();
      personas.forEach((persona) async {
        await _accountService.deletePersona(persona);
      });

      await _socialRecoveryService.deleteHelpingContactDecks();

      await _cloudDatabase.removeAll();
      await _mainnetDatabase.removeAll();
      await _testnetDatabase.removeAll();
      await _configurationService.removeAll();

      _authService.reset();
      memoryValues = MemoryValues();

      emit(ForgetExistState(state.isChecked, false));
    });

    on<ConfirmEraseDeviceInfoEvent>((event, emit) async {
      emit(ForgetExistState(state.isChecked, true));
      deregisterPushNotification();
      await _autonomyService.clearLinkedAddresses();

      final List<Persona> personas =
          await _cloudDatabase.personaDao.getPersonas();
      personas.forEach((persona) async {
        await _accountService.deletePersona(persona);
      });

      await _socialRecoveryService.deleteHelpingContactDecks();

      await _cloudDatabase.removeAll();
      await _mainnetDatabase.removeAll();
      await _testnetDatabase.removeAll();
      await _configurationService.removeAll();

      _authService.reset();
      memoryValues = MemoryValues();

      emit(ForgetExistState(state.isChecked, false));
    });
  }
}
