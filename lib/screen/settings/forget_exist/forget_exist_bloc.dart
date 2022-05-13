import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgetExistBloc extends Bloc<ForgetExistEvent, ForgetExistState> {
  AccountService _accountService;
  AutonomyService _autonomyService;
  IAPApi _iapApi;
  CloudDatabase _cloudDatabase;
  AppDatabase _mainnetDatabase;
  AppDatabase _testnetDatabase;
  ConfigurationService _configurationService;

  ForgetExistBloc(
      this._accountService,
      this._autonomyService,
      this._iapApi,
      this._cloudDatabase,
      this._mainnetDatabase,
      this._testnetDatabase,
      this._configurationService)
      : super(ForgetExistState(false, null)) {
    on<UpdateCheckEvent>((event, emit) async {
      emit(ForgetExistState(event.isChecked, state.isProcessing));
    });

    on<ConfirmForgetExistEvent>((event, emit) async {
      emit(ForgetExistState(state.isChecked, true));

      await _autonomyService.clearLinkedAddresses();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String? deviceId = await MigrationUtil.getBackupDeviceID();
      final requester = "$deviceId\_${packageInfo.packageName}";
      await _iapApi.deleteAllProfiles(requester);

      final List<Persona> personas =
          await _cloudDatabase.personaDao.getPersonas();
      personas.forEach((persona) async {
        await _accountService.deletePersona(persona);
      });

      await _cloudDatabase.removeAll();
      await _mainnetDatabase.removeAll();
      await _testnetDatabase.removeAll();
      await _configurationService.removeAll();

      emit(ForgetExistState(state.isChecked, false));
    });
  }
}
