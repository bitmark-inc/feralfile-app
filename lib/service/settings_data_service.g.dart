// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsDataBackup _$SettingsDataBackupFromJson(Map<String, dynamic> json) =>
    SettingsDataBackup(
      immediatePlaybacks: json['immediatePlaybacks'] as bool,
      isAnalyticsEnabled: json['isAnalyticsEnabled'] as bool,
      uxGuideStep: json['uxGuideStep'] as int?,
      finishedSurveys: (json['finishedSurveys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenMainnetTokenIDs: (json['hiddenMainnetTokenIDs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenTestnetTokenIDs: (json['hiddenTestnetTokenIDs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenFullAccountsFromGallery:
          (json['hiddenFullAccountsFromGallery'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      hiddenLinkedAccountsFromGallery:
          (json['hiddenLinkedAccountsFromGallery'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$SettingsDataBackupToJson(SettingsDataBackup instance) =>
    <String, dynamic>{
      'immediatePlaybacks': instance.immediatePlaybacks,
      'isAnalyticsEnabled': instance.isAnalyticsEnabled,
      'uxGuideStep': instance.uxGuideStep,
      'finishedSurveys': instance.finishedSurveys,
      'hiddenMainnetTokenIDs': instance.hiddenMainnetTokenIDs,
      'hiddenTestnetTokenIDs': instance.hiddenTestnetTokenIDs,
      'hiddenFullAccountsFromGallery': instance.hiddenFullAccountsFromGallery,
      'hiddenLinkedAccountsFromGallery':
          instance.hiddenLinkedAccountsFromGallery,
    };
