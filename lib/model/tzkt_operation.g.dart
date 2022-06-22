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
      initiator: json['initiator'] == null
          ? null
          : TZKTActor.fromJson(json['initiator'] as Map<String, dynamic>),
      sender: json['sender'] == null
          ? null
          : TZKTActor.fromJson(json['sender'] as Map<String, dynamic>),
      target: json['target'] == null
          ? null
          : TZKTActor.fromJson(json['target'] as Map<String, dynamic>),
      gasLimit: json['gasLimit'] as int,
      gasUsed: json['gasUsed'] as int,
      storageLimit: json['storageLimit'] as int,
      storageUsed: json['storageUsed'] as int,
      bakerFee: json['bakerFee'] as int,
      storageFee: json['storageFee'] as int,
      allocationFee: json['allocationFee'] as int,
      amount: json['amount'] as int,
      status: json['status'] as String?,
      hasInternals: json['hasInternals'] as bool,
      quote: TZKTQuote.fromJson(json['quote'] as Map<String, dynamic>),
      parameter: json['parameter'] == null
          ? null
          : TZKTParameter.fromJson(json['parameter'] as Map<String, dynamic>),
    );

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
    };

TZKTActor _$TZKTActorFromJson(Map<String, dynamic> json) => TZKTActor(
      address: json['address'] as String,
    );

Map<String, dynamic> _$TZKTActorToJson(TZKTActor instance) => <String, dynamic>{
      'address': instance.address,
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
