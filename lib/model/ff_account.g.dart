// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ff_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FFContract _$FFContractFromJson(Map<String, dynamic> json) => FFContract(
      json['name'] as String,
      json['blockchainType'] as String,
      json['address'] as String,
    );

Map<String, dynamic> _$FFContractToJson(FFContract instance) =>
    <String, dynamic>{
      'name': instance.name,
      'blockchainType': instance.blockchainType,
      'address': instance.address,
    };

FeralfileError _$FeralfileErrorFromJson(Map<String, dynamic> json) =>
    FeralfileError(
      (json['code'] ?? json['id']) as int,
      json['message'] as String,
    );

Map<String, dynamic> _$FeralfileErrorToJson(FeralfileError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };

ResaleResponse _$ResaleResponseFromJson(Map<String, dynamic> json) =>
    ResaleResponse(
      FeralFileResaleInfo.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResaleResponseToJson(ResaleResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

FeralFileResaleInfo _$FeralFileResaleInfoFromJson(Map<String, dynamic> json) =>
    FeralFileResaleInfo(
      json['exhibitionID'] as String,
      json['saleType'] as String,
      (json['platform'] as num).toDouble(),
      (json['artist'] as num).toDouble(),
      (json['seller'] as num).toDouble(),
      (json['curator'] as num).toDouble(),
      (json['partner'] as num).toDouble(),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FeralFileResaleInfoToJson(
        FeralFileResaleInfo instance) =>
    <String, dynamic>{
      'exhibitionID': instance.exhibitionID,
      'saleType': instance.saleType,
      'platform': instance.platform,
      'artist': instance.artist,
      'seller': instance.seller,
      'curator': instance.curator,
      'partner': instance.partner,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
