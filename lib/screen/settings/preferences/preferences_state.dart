//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

abstract class PreferenceEvent {}

class PreferenceInfoEvent extends PreferenceEvent {}

class PreferenceUpdateEvent extends PreferenceEvent {
  final PreferenceState newState;

  PreferenceUpdateEvent(this.newState);
}

class PreferenceState {
  bool isDevicePasscodeEnabled;
  final bool isAnalyticEnabled;
  final String authMethodName;
  final bool hasHiddenArtworks;

  PreferenceState(
    this.isDevicePasscodeEnabled,
    this.isAnalyticEnabled,
    this.authMethodName,
    this.hasHiddenArtworks,
  );

  PreferenceState copyWith({
    bool? isDevicePasscodeEnabled,
    bool? isAnalyticEnabled,
    String? authMethodName,
    bool? hasHiddenArtworks,
  }) =>
      PreferenceState(
        isDevicePasscodeEnabled ?? this.isDevicePasscodeEnabled,
        isAnalyticEnabled ?? this.isAnalyticEnabled,
        authMethodName ?? this.authMethodName,
        hasHiddenArtworks ?? this.hasHiddenArtworks,
      );
}
