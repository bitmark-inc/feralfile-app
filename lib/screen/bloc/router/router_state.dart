part of 'router_bloc.dart';

abstract class RouterEvent {}

class DefineViewRoutingEvent extends RouterEvent {}

class RestoreCloudDatabaseRoutingEvent extends RouterEvent {
  final String version;

  RestoreCloudDatabaseRoutingEvent(this.version);
}

enum OnboardingStep {
  undefined,
  startScreen,
  newAccountPage,
  restore,
  iCloud,
  security,
  dashboard,
}

class RouterState {
  OnboardingStep onboardingStep = OnboardingStep.undefined;
  String backupVersion = "";
  bool isLoading = false;

  RouterState({
    required this.onboardingStep,
    this.backupVersion = "",
    this.isLoading = false,
  });
}
