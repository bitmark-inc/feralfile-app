// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharePostcardResponse _$SharePostcardResponseFromJson(
        Map<String, dynamic> json) =>
    SharePostcardResponse(
      deeplink: json['deeplink'] as String?,
    );

Map<String, dynamic> _$SharePostcardResponseToJson(
        SharePostcardResponse instance) =>
    <String, dynamic>{
      'deeplink': instance.deeplink,
    };

SharePostcardRequest _$SharePostcardRequestFromJson(
        Map<String, dynamic> json) =>
    SharePostcardRequest(
      tokenId: json['tokenId'] as String?,
      signature: json['signature'] as String?,
    );

Map<String, dynamic> _$SharePostcardRequestToJson(
        SharePostcardRequest instance) =>
    <String, dynamic>{
      'tokenId': instance.tokenId,
      'signature': instance.signature,
    };
