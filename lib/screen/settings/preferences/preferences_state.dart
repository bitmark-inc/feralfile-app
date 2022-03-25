abstract class PreferenceEvent {}

class PreferenceInfoEvent extends PreferenceEvent {}

class PreferenceUpdateEvent extends PreferenceEvent {
  final PreferenceState newState;

  PreferenceUpdateEvent(this.newState);
}

class PreferenceState {
  final bool isImmediatePlaybackEnabled;
  bool isDevicePasscodeEnabled;
  final bool isNotificationEnabled;
  final bool isAnalyticEnabled;
  final String authMethodName;

  PreferenceState(
    this.isImmediatePlaybackEnabled,
    this.isDevicePasscodeEnabled,
    this.isNotificationEnabled,
    this.isAnalyticEnabled,
    this.authMethodName,
  );
}
