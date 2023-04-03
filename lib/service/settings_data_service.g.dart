// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsDataBackup _$SettingsDataBackupFromJson(Map<String, dynamic> json) =>
    SettingsDataBackup(
      addresses:
          (json['addresses'] as List<dynamic>).map((e) => e as String).toList(),
      isAnalyticsEnabled: json['isAnalyticsEnabled'] as bool,
      finishedSurveys: (json['finishedSurveys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenMainnetTokenIDs: (json['hiddenMainnetTokenIDs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenTestnetTokenIDs: (json['hiddenTestnetTokenIDs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hiddenLinkedAccountsFromGallery:
          (json['hiddenLinkedAccountsFromGallery'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      hiddenAddressesFromGallery:
          (json['hiddenAddressesFromGallery'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      playlists: (json['playlists'] as List<dynamic>?)
          ?.map((e) => PlayListModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SettingsDataBackupToJson(SettingsDataBackup instance) =>
    <String, dynamic>{
      'addresses': instance.addresses,
      'isAnalyticsEnabled': instance.isAnalyticsEnabled,
      'finishedSurveys': instance.finishedSurveys,
      'hiddenMainnetTokenIDs': instance.hiddenMainnetTokenIDs,
      'hiddenTestnetTokenIDs': instance.hiddenTestnetTokenIDs,
      'hiddenLinkedAccountsFromGallery':
          instance.hiddenLinkedAccountsFromGallery,
      'hiddenAddressesFromGallery': instance.hiddenAddressesFromGallery,
      'playlists': instance.playlists,
    };
