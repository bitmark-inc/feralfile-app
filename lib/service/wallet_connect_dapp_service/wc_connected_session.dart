// part of 'wallet_connect_dapp_service.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wallet_connect/wallet_connect.dart';
part 'wc_connected_session.g.dart';

@JsonSerializable()
class WCConnectedSession {
  final WCSessionStore sessionStore;
  final List<String> accounts;

  WCConnectedSession({
    required this.sessionStore,
    required this.accounts,
  });

  factory WCConnectedSession.fromJson(Map<String, dynamic> json) =>
      _$WCConnectedSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WCConnectedSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
