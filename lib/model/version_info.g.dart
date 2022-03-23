// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionsInfo _$VersionsInfoFromJson(Map<String, dynamic> json) => VersionsInfo(
      productionIOS:
          VersionInfo.fromJson(json['productionIOS'] as Map<String, dynamic>),
      productionAndroid: VersionInfo.fromJson(
          json['productionAndroid'] as Map<String, dynamic>),
      testIOS: VersionInfo.fromJson(json['testIOS'] as Map<String, dynamic>),
      testAndroid:
          VersionInfo.fromJson(json['testAndroid'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VersionsInfoToJson(VersionsInfo instance) =>
    <String, dynamic>{
      'productionIOS': instance.productionIOS,
      'productionAndroid': instance.productionAndroid,
      'testIOS': instance.testIOS,
      'testAndroid': instance.testAndroid,
    };

VersionInfo _$VersionInfoFromJson(Map<String, dynamic> json) => VersionInfo(
      requiredVersion: json['requiredVersion'] as String,
      link: json['link'] as String,
    );

Map<String, dynamic> _$VersionInfoToJson(VersionInfo instance) =>
    <String, dynamic>{
      'requiredVersion': instance.requiredVersion,
      'link': instance.link,
    };
