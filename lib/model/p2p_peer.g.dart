// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'p2p_peer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

P2PPeer _$P2PPeerFromJson(Map<String, dynamic> json) => P2PPeer(
      json['id'] as String,
      json['name'] as String,
      json['publicKey'] as String,
      json['relayServer'] as String,
      json['version'] as String,
      json['icon'] as String?,
      json['appURL'] as String?,
    );

Map<String, dynamic> _$P2PPeerToJson(P2PPeer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'publicKey': instance.publicKey,
      'relayServer': instance.relayServer,
      'version': instance.version,
      'icon': instance.icon,
      'appURL': instance.appURL,
    };
