// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MigrationData _$MigrationDataFromJson(Map<String, dynamic> json) =>
    MigrationData(
      personas: (json['personas'] as List<dynamic>)
          .map((e) => MigrationPersona.fromJson(e as Map<String, dynamic>))
          .toList(),
      ffTokenConnections: (json['ffTokenConnections'] as List<dynamic>)
          .map((e) =>
              MigrationFFTokenConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
      ffWeb3Connections: (json['ffWeb3Connections'] as List<dynamic>)
          .map((e) =>
              MigrationFFWeb3Connection.fromJson(e as Map<String, dynamic>))
          .toList(),
      walletBeaconConnections:
          (json['walletBeaconConnections'] as List<dynamic>)
              .map((e) => MigrationWalletBeaconConnection.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$MigrationDataToJson(MigrationData instance) =>
    <String, dynamic>{
      'personas': instance.personas,
      'ffTokenConnections': instance.ffTokenConnections,
      'ffWeb3Connections': instance.ffWeb3Connections,
      'walletBeaconConnections': instance.walletBeaconConnections,
    };

MigrationPersona _$MigrationPersonaFromJson(Map<String, dynamic> json) =>
    MigrationPersona(
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MigrationPersonaToJson(MigrationPersona instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'createdAt': instance.createdAt.toIso8601String(),
    };

MigrationFFTokenConnection _$MigrationFFTokenConnectionFromJson(
        Map<String, dynamic> json) =>
    MigrationFFTokenConnection(
      token: json['token'] as String,
      source: json['source'] as String,
      ffAccount: FFAccount.fromJson(json['ffAccount'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MigrationFFTokenConnectionToJson(
        MigrationFFTokenConnection instance) =>
    <String, dynamic>{
      'token': instance.token,
      'source': instance.source,
      'ffAccount': instance.ffAccount,
      'createdAt': instance.createdAt.toIso8601String(),
    };

MigrationFFWeb3Connection _$MigrationFFWeb3ConnectionFromJson(
        Map<String, dynamic> json) =>
    MigrationFFWeb3Connection(
      topic: json['topic'] as String,
      address: json['address'] as String,
      source: json['source'] as String,
      ffAccount: FFAccount.fromJson(json['ffAccount'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MigrationFFWeb3ConnectionToJson(
        MigrationFFWeb3Connection instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'address': instance.address,
      'source': instance.source,
      'ffAccount': instance.ffAccount,
      'createdAt': instance.createdAt.toIso8601String(),
    };

MigrationWalletBeaconConnection _$MigrationWalletBeaconConnectionFromJson(
        Map<String, dynamic> json) =>
    MigrationWalletBeaconConnection(
      tezosWalletConnection: TezosConnection.fromJson(
          json['tezosWalletConnection'] as Map<String, dynamic>),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MigrationWalletBeaconConnectionToJson(
        MigrationWalletBeaconConnection instance) =>
    <String, dynamic>{
      'tezosWalletConnection': instance.tezosWalletConnection,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
    };
