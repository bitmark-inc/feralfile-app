// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_token_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginTokenInfo _$OriginTokenInfoFromJson(Map<String, dynamic> json) =>
    OriginTokenInfo(
      id: json['id'] as String,
      blockchain: json['blockchain'] as String?,
      fungible: json['fungible'] as bool?,
      contractType: json['contractType'] as String?,
    );

Map<String, dynamic> _$OriginTokenInfoToJson(OriginTokenInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blockchain': instance.blockchain,
      'fungible': instance.fungible,
      'contractType': instance.contractType,
    };
