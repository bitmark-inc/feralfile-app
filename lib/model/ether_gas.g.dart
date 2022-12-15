// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ether_gas.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EtherGas _$EtherGasFromJson(Map<String, dynamic> json) => EtherGas(
      code: json['code'] as int,
      data: EtherGasData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EtherGasToJson(EtherGas instance) => <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
    };

EtherGasData _$EtherGasDataFromJson(Map<String, dynamic> json) => EtherGasData(
      rapid: json['rapid'] as int?,
      fast: json['fast'] as int?,
      standard: json['standard'] as int?,
      slow: json['slow'] as int?,
      timestamp: json['timestamp'] as int?,
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

EtherGasDataOracle _$EtherGasDataOracleFromJson(Map<String, dynamic> json) =>
    EtherGasDataOracle(
      safeLow: double.parse(json['safeLow'].toString()),
      standard: double.parse(json['standard'].toString()),
      fast: double.parse(json['fast'].toString()),
      fastest: double.parse(json['fastest'].toString()),
      currentBaseFee: double.parse(json['currentBaseFee'].toString()),
      recommendedBaseFee: double.parse(json['recommendedBaseFee'].toString()),
    );
