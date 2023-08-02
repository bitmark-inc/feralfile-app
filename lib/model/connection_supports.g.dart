// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_supports.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeralFileConnection _$FeralFileConnectionFromJson(Map<String, dynamic> json) =>
    FeralFileConnection(
      source: json['source'] as String,
      ffAccount: FFAccount.fromJson(json['ffAccount'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeralFileConnectionToJson(
        FeralFileConnection instance) =>
    <String, dynamic>{
      'source': instance.source,
      'ffAccount': instance.ffAccount,
    };

FeralFileWeb3Connection _$FeralFileWeb3ConnectionFromJson(
        Map<String, dynamic> json) =>
    FeralFileWeb3Connection(
      personaAddress: json['personaAddress'] as String,
      source: json['source'] as String,
      ffAccount: FFAccount.fromJson(json['ffAccount'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeralFileWeb3ConnectionToJson(
        FeralFileWeb3Connection instance) =>
    <String, dynamic>{
      'personaAddress': instance.personaAddress,
      'source': instance.source,
      'ffAccount': instance.ffAccount,
    };

BeaconConnectConnection _$BeaconConnectConnectionFromJson(
        Map<String, dynamic> json) =>
    BeaconConnectConnection(
      personaUuid: json['personaUuid'] as String,
      index: json['index'] == null ? 0 : json['index'] as int,
      peer: P2PPeer.fromJson(json['peer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BeaconConnectConnectionToJson(
        BeaconConnectConnection instance) =>
    <String, dynamic>{
      'personaUuid': instance.personaUuid,
      'index': instance.index,
      'peer': instance.peer,
    };

LedgerConnection _$LedgerConnectionFromJson(Map<String, dynamic> json) =>
    LedgerConnection(
      ledgerName: json['ledgerName'] as String,
      ledgerUUID: json['ledgerUUID'] as String,
      etheremAddress: (json['etheremAddress'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tezosAddress: (json['tezosAddress'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$LedgerConnectionToJson(LedgerConnection instance) =>
    <String, dynamic>{
      'ledgerName': instance.ledgerName,
      'ledgerUUID': instance.ledgerUUID,
      'etheremAddress': instance.etheremAddress,
      'tezosAddress': instance.tezosAddress,
    };
