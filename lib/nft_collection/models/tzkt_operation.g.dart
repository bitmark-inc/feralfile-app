// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tzkt_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TZKTTokenTransfer _$TZKTTokenTransferFromJson(Map<String, dynamic> json) =>
    TZKTTokenTransfer(
      id: json['id'] as int,
      level: json['level'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: json['amount'] as String?,
      token: json['token'] == null
          ? null
          : TZKTToken.fromJson(json['token'] as Map<String, dynamic>),
      from: json['from'] == null
          ? null
          : TZKTActor.fromJson(json['from'] as Map<String, dynamic>),
      to: json['to'] == null
          ? null
          : TZKTActor.fromJson(json['to'] as Map<String, dynamic>),
      transactionId: json['transactionId'] as int?,
      originationId: json['originationId'] as int?,
      migrationId: json['migrationId'] as int?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$TZKTTokenTransferToJson(TZKTTokenTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'level': instance.level,
      'timestamp': instance.timestamp.toIso8601String(),
      'amount': instance.amount,
      'token': instance.token,
      'from': instance.from,
      'to': instance.to,
      'transactionId': instance.transactionId,
      'originationId': instance.originationId,
      'migrationId': instance.migrationId,
      'status': instance.status,
    };

TZKTToken _$TZKTTokenFromJson(Map<String, dynamic> json) => TZKTToken(
      id: json['id'] as int,
      contract: json['contract'] == null
          ? null
          : TZKTActor.fromJson(json['contract'] as Map<String, dynamic>),
      tokenId: json['tokenId'] as String?,
      standard: json['standard'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TZKTTokenToJson(TZKTToken instance) => <String, dynamic>{
      'id': instance.id,
      'contract': instance.contract,
      'tokenId': instance.tokenId,
      'standard': instance.standard,
      'metadata': instance.metadata,
    };

TZKTActor _$TZKTActorFromJson(Map<String, dynamic> json) => TZKTActor(
      address: json['address'] as String,
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$TZKTActorToJson(TZKTActor instance) => <String, dynamic>{
      'address': instance.address,
      'alias': instance.alias,
    };
