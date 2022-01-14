abstract class PreferenceEvent {}

class PreferenceInfoEvent extends PreferenceEvent {}

class PreferenceUpdateEvent extends PreferenceEvent {
  final PreferenceState newState;

  PreferenceUpdateEvent(this.newState);
}

class PreferenceState {
  bool isDevicePasscodeEnabled;
  final bool isNotificationEnabled;
  final bool isAnalyticEnabled;

  PreferenceState(this.isDevicePasscodeEnabled, this.isNotificationEnabled, this.isAnalyticEnabled);}