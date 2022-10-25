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
  final bool isImmediateInfoViewEnabled;
  bool isDevicePasscodeEnabled;
  bool isNotificationEnabled;
  final bool isAnalyticEnabled;
  final String authMethodName;
  final bool hasHiddenArtworks;
  final bool hasPendingSettings;

  PreferenceState(
    this.isImmediateInfoViewEnabled,
    this.isDevicePasscodeEnabled,
    this.isNotificationEnabled,
    this.isAnalyticEnabled,
    this.authMethodName,
    this.hasHiddenArtworks,
    this.hasPendingSettings,
  );

  PreferenceState copyWith({
    bool? isImmediateInfoViewEnabled,
    bool? isDevicePasscodeEnabled,
    bool? isNotificationEnabled,
    bool? isAnalyticEnabled,
    String? authMethodName,
    bool? hasHiddenArtworks,
    bool? hasPendingSettings,
  }) {
    return PreferenceState(
      isImmediateInfoViewEnabled ?? this.isImmediateInfoViewEnabled,
      isDevicePasscodeEnabled ?? this.isDevicePasscodeEnabled,
      isNotificationEnabled ?? this.isNotificationEnabled,
      isAnalyticEnabled ?? this.isAnalyticEnabled,
      authMethodName ?? this.authMethodName,
      hasHiddenArtworks ?? this.hasHiddenArtworks,
      hasPendingSettings ?? this.hasPendingSettings,
    );
  }
}
