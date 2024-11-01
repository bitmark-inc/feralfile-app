// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ether_gas.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EtherGas _$EtherGasFromJson(Map<String, dynamic> json) => EtherGas(
      code: (json['code'] as num).toInt(),
      data: EtherGasData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EtherGasToJson(EtherGas instance) => <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
    };

EtherGasData _$EtherGasDataFromJson(Map<String, dynamic> json) => EtherGasData(
      rapid: (json['rapid'] as num?)?.toInt(),
      fast: (json['fast'] as num?)?.toInt(),
      standard: (json['standard'] as num?)?.toInt(),
      slow: (json['slow'] as num?)?.toInt(),
      timestamp: (json['timestamp'] as num?)?.toInt(),
      priceUSD: (json['priceUSD'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EtherGasDataToJson(EtherGasData instance) =>
    <String, dynamic>{
      'rapid': instance.rapid,
      'fast': instance.fast,
      'standard': instance.standard,
      'slow': instance.slow,
      'timestamp': instance.timestamp,
      'priceUSD': instance.priceUSD,
    };
