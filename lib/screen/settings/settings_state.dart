import 'package:autonomy_flutter/model/network.dart';

abstract class SettingsEvent {}

class SettingsGetBalanceEvent extends SettingsEvent {}

class SettingsState {
  String? xtzBalance;
  String? ethBalance;
  Network? network;

  SettingsState({this.ethBalance, this.xtzBalance, this.network});
}
