// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_supports.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeaconConnectConnection _$BeaconConnectConnectionFromJson(
        Map<String, dynamic> json) =>
    BeaconConnectConnection(
      personaUuid: json['personaUuid'] as String,
      index: json['index'] as int? ?? 0,
      peer: P2PPeer.fromJson(json['peer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BeaconConnectConnectionToJson(
        BeaconConnectConnection instance) =>
    <String, dynamic>{
      'personaUuid': instance.personaUuid,
      'index': instance.index,
      'peer': instance.peer,
    };
