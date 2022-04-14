abstract class PreferenceEvent {}

class PreferenceInfoEvent extends PreferenceEvent {}

class PreferenceUpdateEvent extends PreferenceEvent {
  final PreferenceState newState;

  PreferenceUpdateEvent(this.newState);
}

class PreferenceState {
  final String? gallerySortBy;
  final bool isImmediatePlaybackEnabled;
  bool isDevicePasscodeEnabled;
  final bool isNotificationEnabled;
  final bool isAnalyticEnabled;
  final String authMethodName;

  PreferenceState(
    this.gallerySortBy,
    this.isImmediatePlaybackEnabled,
    this.isDevicePasscodeEnabled,
    this.isNotificationEnabled,
    this.isAnalyticEnabled,
    this.authMethodName,
  );

  PreferenceState copyWith({
    String? gallerySortBy,
    bool? isImmediatePlaybackEnabled,
    bool? isDevicePasscodeEnabled,
    bool? isNotificationEnabled,
    bool? isAnalyticEnabled,
    String? authMethodName,
  }) {
    return PreferenceState(
      gallerySortBy ?? this.gallerySortBy,
      isImmediatePlaybackEnabled ?? this.isImmediatePlaybackEnabled,
      isDevicePasscodeEnabled ?? this.isDevicePasscodeEnabled,
      isNotificationEnabled ?? this.isNotificationEnabled,
      isAnalyticEnabled ?? this.isAnalyticEnabled,
      authMethodName ?? this.authMethodName,
    );
  }
}
