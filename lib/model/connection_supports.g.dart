// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_supports.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeralFileConnection _$FeralFileConnectionFromJson(Map<String, dynamic> json) {
  return FeralFileConnection(
    source: json['source'] as String,
    ffAccount: FFAccount.fromJson(json['ffAccount'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FeralFileConnectionToJson(
        FeralFileConnection instance) =>
    <String, dynamic>{
      'source': instance.source,
      'ffAccount': instance.ffAccount,
    };

WalletConnectConnection _$WalletConnectConnectionFromJson(
    Map<String, dynamic> json) {
  return WalletConnectConnection(
    personaUuid: json['personaUuid'] as String,
    sessionStore:
        WCSessionStore.fromJson(json['sessionStore'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$WalletConnectConnectionToJson(
        WalletConnectConnection instance) =>
    <String, dynamic>{
      'personaUuid': instance.personaUuid,
      'sessionStore': instance.sessionStore,
    };

BeaconConnectConnection _$BeaconConnectConnectionFromJson(
    Map<String, dynamic> json) {
  return BeaconConnectConnection(
    personaUuid: json['personaUuid'] as String,
    peer: P2PPeer.fromJson(json['peer'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$BeaconConnectConnectionToJson(
        BeaconConnectConnection instance) =>
    <String, dynamic>{
      'personaUuid': instance.personaUuid,
      'peer': instance.peer,
    };
