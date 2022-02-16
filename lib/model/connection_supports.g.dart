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
