// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tezos_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TezosConnection _$TezosConnectionFromJson(Map<String, dynamic> json) =>
    TezosConnection(
      address: json['address'] as String,
      peer: Peer.fromJson(json['peer'] as Map<String, dynamic>),
      permissionResponse: PermissionResponse.fromJson(
          json['permissionResponse'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TezosConnectionToJson(TezosConnection instance) =>
    <String, dynamic>{
      'address': instance.address,
      'peer': instance.peer,
      'permissionResponse': instance.permissionResponse,
    };

Peer _$PeerFromJson(Map<String, dynamic> json) => Peer(
      relayServer: json['relayServer'] as String,
      id: json['id'] as String,
      kind: json['kind'] as String?,
      publicKey: json['publicKey'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$PeerToJson(Peer instance) => <String, dynamic>{
      'relayServer': instance.relayServer,
      'id': instance.id,
      'kind': instance.kind,
      'publicKey': instance.publicKey,
      'name': instance.name,
      'version': instance.version,
    };

PermissionResponse _$PermissionResponseFromJson(Map<String, dynamic> json) =>
    PermissionResponse(
      id: json['id'] as String,
      version: json['version'] as String,
      requestOrigin:
          RequestOrigin.fromJson(json['requestOrigin'] as Map<String, dynamic>),
      scopes:
          (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
      publicKey: json['publicKey'] as String?,
      network: json['network'] == null
          ? null
          : TezosNetwork.fromJson(json['network'] as Map<String, dynamic>),
      account: json['account'] == null
          ? null
          : BeaconAccount.fromJson(json['account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PermissionResponseToJson(PermissionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'requestOrigin': instance.requestOrigin,
      'scopes': instance.scopes,
      'publicKey': instance.publicKey,
      'network': instance.network,
      'account': instance.account,
    };

BeaconAccount _$BeaconAccountFromJson(Map<String, dynamic> json) =>
    BeaconAccount(
      accountId: json['accountId'] as String,
      network: TezosNetwork.fromJson(json['network'] as Map<String, dynamic>),
      publicKey: json['publicKey'] as String,
      address: json['address'] as String,
    );

Map<String, dynamic> _$BeaconAccountToJson(BeaconAccount instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'network': instance.network,
      'publicKey': instance.publicKey,
      'address': instance.address,
    };

TezosNetwork _$TezosNetworkFromJson(Map<String, dynamic> json) => TezosNetwork(
      type: json['type'] as String,
    );

Map<String, dynamic> _$TezosNetworkToJson(TezosNetwork instance) =>
    <String, dynamic>{
      'type': instance.type,
    };

RequestOrigin _$RequestOriginFromJson(Map<String, dynamic> json) =>
    RequestOrigin(
      kind: json['kind'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$RequestOriginToJson(RequestOrigin instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'id': instance.id,
    };
