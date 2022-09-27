//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'router_bloc.dart';

abstract class RouterEvent {}

class DefineViewRoutingEvent extends RouterEvent {}

class RestoreCloudDatabaseRoutingEvent extends RouterEvent {
  RestoreCloudDatabaseRoutingEvent();
}

enum OnboardingStep {
  undefined,
  startScreen,
  restore,
  dashboard,
  restoreWithEmergencyContact,
}

class RouterState {
  OnboardingStep onboardingStep = OnboardingStep.undefined;
  bool isRestoring = false;

  RouterState({
    required this.onboardingStep,
    this.isRestoring = false,
  });

  RouterState copyWith({
    OnboardingStep? onboardingStep,
    bool? isRestoring,
  }) {
    return RouterState(
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}
