// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wc2_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wc2PermissionResponse _$Wc2PermissionResponseFromJson(
        Map<String, dynamic> json) =>
    Wc2PermissionResponse(
      signature: json['signature'] as String,
      permissionResults: (json['permissionResults'] as List<dynamic>)
          .map((e) => Wc2PermissionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$Wc2PermissionResponseToJson(
        Wc2PermissionResponse instance) =>
    <String, dynamic>{
      'signature': instance.signature,
      'permissionResults': instance.permissionResults,
    };

Wc2PermissionResult _$Wc2PermissionResultFromJson(Map<String, dynamic> json) =>
    Wc2PermissionResult(
      type: json['type'] as String,
      result: Wc2ChainResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$Wc2PermissionResultToJson(
        Wc2PermissionResult instance) =>
    <String, dynamic>{
      'type': instance.type,
      'result': instance.result,
    };

Wc2ChainResult _$Wc2ChainResultFromJson(Map<String, dynamic> json) =>
    Wc2ChainResult(
      chains: (json['chains'] as List<dynamic>)
          .map((e) => Wc2Chain.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$Wc2ChainResultToJson(Wc2ChainResult instance) =>
    <String, dynamic>{
      'chains': instance.chains,
    };

Wc2Chain _$Wc2ChainFromJson(Map<String, dynamic> json) => Wc2Chain(
      chain: json['chain'] as String,
      address: json['address'] as String,
      publicKey: json['publicKey'] as String?,
      signature: json['signature'] as String?,
    );

Map<String, dynamic> _$Wc2ChainToJson(Wc2Chain instance) => <String, dynamic>{
      'chain': instance.chain,
      'address': instance.address,
      'publicKey': instance.publicKey,
      'signature': instance.signature,
    };
