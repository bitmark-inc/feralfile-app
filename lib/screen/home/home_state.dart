import 'package:autonomy_flutter/database/entity/asset_token.dart';

abstract class HomeEvent {}

class HomeConnectWCEvent extends HomeEvent {
  final String uri;

  HomeConnectWCEvent(this.uri);
}

class HomeConnectTZEvent extends HomeEvent {
  final String uri;

  HomeConnectTZEvent(this.uri);
}

class HomeCheckFeralFileLoginEvent extends HomeEvent {}

class HomeState {
  bool? isFeralFileLoggedIn;
  List<AssetToken> ffAssets = [];
  List<AssetToken> ethAssets = [];
  List<AssetToken> xtzAssets = [];
}