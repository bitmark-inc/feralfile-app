import 'package:autonomy_flutter/model/asset.dart';

abstract class HomeEvent {}

class HomeConnectWCEvent extends HomeEvent {
  final String uri;

  HomeConnectWCEvent(this.uri);
}

class HomeCheckFeralFileLoginEvent extends HomeEvent {}

class HomeState {
  bool? isFeralFileLoggedIn;
  List<Asset> assets = [];
}