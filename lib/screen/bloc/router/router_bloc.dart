import 'package:autonomy_flutter/database/app_database.dart';
import 'package:bloc/bloc.dart';

part 'router_state.dart';

class RouterBloc extends Bloc<RouterEvent, RouterState> {
  CloudDatabase _cloudDB;

  RouterBloc(this._cloudDB)
      : super(RouterState(onboardingStep: OnboardingStep.undefined)) {
    on<DefineViewRoutingEvent>((event, emit) async {
      if (state.onboardingStep != OnboardingStep.undefined) return;

      final personas = await _cloudDB.personaDao.getPersonas();
      if (personas.isEmpty) {
        emit(RouterState(onboardingStep: OnboardingStep.startScreen));
      } else {
        emit(RouterState(onboardingStep: OnboardingStep.dashboard));
      }
    });
  }
}
