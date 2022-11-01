// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Otp _$OtpFromJson(Map<String, dynamic> json) => Otp(
      json['code'] as String,
      json['expireAt'] == null
          ? null
          : DateTime.parse(json['expireAt'] as String),
    );

Map<String, dynamic> _$OtpToJson(Otp instance) => <String, dynamic>{
      'code': instance.code,
      'expireAt': instance.expireAt?.toIso8601String(),
    };
