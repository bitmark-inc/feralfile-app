// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tzkt_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TZKTOperation _$TZKTOperationFromJson(Map<String, dynamic> json) =>
    TZKTOperation(
      type: json['type'] as String,
      id: json['id'] as int,
      level: json['level'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      block: json['block'] as String,
      hash: json['hash'] as String,
      counter: json['counter'] as int,
      gasLimit: json['gasLimit'] as int,
      gasUsed: json['gasUsed'] as int,
      bakerFee: json['bakerFee'] as int,
      quote: TZKTQuote.fromJson(json['quote'] as Map<String, dynamic>),
      initiator: json['initiator'] == null
          ? null
          : TZKTActor.fromJson(json['initiator'] as Map<String, dynamic>),
      sender: json['sender'] == null
          ? null
          : TZKTActor.fromJson(json['sender'] as Map<String, dynamic>),
      target: json['target'] == null
          ? null
          : TZKTActor.fromJson(json['target'] as Map<String, dynamic>),
      storageLimit: json['storageLimit'] as int?,
      storageUsed: json['storageUsed'] as int?,
      storageFee: json['storageFee'] as int?,
      allocationFee: json['allocationFee'] as int?,
      amount: json['amount'] as int?,
      status: json['status'] as String?,
      hasInternals: json['hasInternals'] as bool?,
      parameter: json['parameter'] == null
          ? null
          : TZKTParameter.fromJson(json['parameter'] as Map<String, dynamic>),
    )..tokenTransfer = json['tokenTransfer'] == null
        ? null
        : TZKTTokenTransfer.fromJson(
            json['tokenTransfer'] as Map<String, dynamic>);

Map<String, dynamic> _$TZKTOperationToJson(TZKTOperation instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'level': instance.level,
      'timestamp': instance.timestamp.toIso8601String(),
      'block': instance.block,
      'hash': instance.hash,
      'counter': instance.counter,
      'sender': instance.sender,
      'initiator': instance.initiator,
      'gasLimit': instance.gasLimit,
      'gasUsed': instance.gasUsed,
      'storageLimit': instance.storageLimit,
      'storageUsed': instance.storageUsed,
      'bakerFee': instance.bakerFee,
      'storageFee': instance.storageFee,
      'allocationFee': instance.allocationFee,
      'target': instance.target,
      'amount': instance.amount,
      'status': instance.status,
      'hasInternals': instance.hasInternals,
      'quote': instance.quote,
      'parameter': instance.parameter,
      'tokenTransfer': instance.tokenTransfer,
    };

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
    )..tokenTransfer = json['tokenTransfer'] == null
        ? null
        : TZKTTokenTransfer.fromJson(
            json['tokenTransfer'] as Map<String, dynamic>);

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
      'tokenTransfer': instance.tokenTransfer,
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

TZKTQuote _$TZKTQuoteFromJson(Map<String, dynamic> json) => TZKTQuote(
      usd: (json['usd'] as num).toDouble(),
    );

Map<String, dynamic> _$TZKTQuoteToJson(TZKTQuote instance) => <String, dynamic>{
      'usd': instance.usd,
    };

TZKTParameter _$TZKTParameterFromJson(Map<String, dynamic> json) =>
    TZKTParameter(
      entrypoint: json['entrypoint'] as String,
      value: json['value'],
    );

Map<String, dynamic> _$TZKTParameterToJson(TZKTParameter instance) =>
    <String, dynamic>{
      'entrypoint': instance.entrypoint,
      'value': instance.value,
    };
