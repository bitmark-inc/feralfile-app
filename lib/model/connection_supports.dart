import 'package:json_annotation/json_annotation.dart';

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:wallet_connect/wc_session_store.dart';

import 'p2p_peer.dart';

part 'connection_supports.g.dart';

@JsonSerializable()
class FeralFileConnection {
  String source;
  FFAccount ffAccount;

  FeralFileConnection({
    required this.source,
    required this.ffAccount,
  });

  factory FeralFileConnection.fromJson(Map<String, dynamic> json) =>
      _$FeralFileConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileConnectionToJson(this);
}

@JsonSerializable()
class WalletConnectConnection {
  String personaUuid;
  WCSessionStore sessionStore;

  WalletConnectConnection({
    required this.personaUuid,
    required this.sessionStore,
  });

  factory WalletConnectConnection.fromJson(Map<String, dynamic> json) =>
      _$WalletConnectConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$WalletConnectConnectionToJson(this);
}

@JsonSerializable()
class BeaconConnectConnection {
  String personaUuid;
  P2PPeer peer;

  BeaconConnectConnection({
    required this.personaUuid,
    required this.peer,
  });

  factory BeaconConnectConnection.fromJson(Map<String, dynamic> json) =>
      _$BeaconConnectConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$BeaconConnectConnectionToJson(this);
}