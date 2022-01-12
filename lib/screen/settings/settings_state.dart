abstract class SettingsEvent {}

class SettingsGetBalanceEvent extends SettingsEvent {}

class SettingsState {
  String? xtzBalance;
  String? ethBalance;
}
