part of 'router_bloc.dart';

abstract class RouterEvent {}

class DefineViewRoutingEvent extends RouterEvent {}

enum OnboardingStep {
  undefined,
  startScreen,
  newAccountPage,
  iCloud,
  security,
  dashboard,
}

class RouterState {
  OnboardingStep onboardingStep = OnboardingStep.undefined;

  RouterState({
    required this.onboardingStep,
  });
}
