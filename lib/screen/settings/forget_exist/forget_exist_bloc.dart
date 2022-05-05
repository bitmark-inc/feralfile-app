import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgetExistBloc extends Bloc<ForgetExistEvent, ForgetExistState> {

  AccountService _accountService;
  CloudDatabase _cloudDatabase;
  AppDatabase _mainnetDatabase;
  AppDatabase _testnetDatabase;
  ConfigurationService _configurationService;

  ForgetExistBloc(this._accountService, this._cloudDatabase, this._mainnetDatabase, this._testnetDatabase, this._configurationService)
      : super(ForgetExistState(false, null)) {

    on<UpdateCheckEvent>((event, emit) async {
      emit(ForgetExistState(event.isChecked, state.isProcessing));
    });

    on<ConfirmForgetExistEvent>((event, emit) async {
      emit(ForgetExistState(state.isChecked, true));

      final List<Persona> personas = await _cloudDatabase.personaDao.getPersonas();
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