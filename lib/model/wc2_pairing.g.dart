// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wc2_pairing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wc2Pairing _$Wc2PairingFromJson(Map<String, dynamic> json) => Wc2Pairing(
      json['topic'] as String,
      json['expiry'] as int? ?? 0,
      json['peerAppMetaData'] == null
          ? null
          : AppMetadata.fromJson(
              json['peerAppMetaData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$Wc2PairingToJson(Wc2Pairing instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'expiry': instance.expiry,
      'peerAppMetaData': instance.peerAppMetaData,
    };
