// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_postcard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedPostcard _$SharedPostcardFromJson(Map<String, dynamic> json) =>
    SharedPostcard(
      json['tokenID'] as String,
      json['owner'] as String,
    );

Map<String, dynamic> _$SharedPostcardToJson(SharedPostcard instance) =>
    <String, dynamic>{
      'tokenID': instance.tokenID,
      'owner': instance.owner,
    };
