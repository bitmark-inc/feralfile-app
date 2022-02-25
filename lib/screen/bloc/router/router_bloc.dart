import 'dart:io';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:bloc/bloc.dart';

part 'router_state.dart';

class RouterBloc extends Bloc<RouterEvent, RouterState> {
  CloudDatabase _cloudDB;

  RouterBloc(this._cloudDB)
      : super(RouterState(onboardingStep: OnboardingStep.undefined)) {
    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) return;

      await MigrationUtil(_cloudDB).migrateIfNeeded(Platform.isIOS);

      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();
      if (personas.isEmpty && connections.isEmpty) {
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      } else {
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
      }
    });
  }
}
