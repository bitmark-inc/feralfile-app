// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsDataBackup _$SettingsDataBackupFromJson(Map<String, dynamic> json) =>
    SettingsDataBackup(
      isAnalyticsEnabled: json['isAnalyticsEnabled'] as bool? ?? true,
      hiddenMainnetTokenIDs: (json['hiddenMainnetTokenIDs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hiddenTestnetTokenIDs: (json['hiddenTestnetTokenIDs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hiddenLinkedAccountsFromGallery:
          (json['hiddenLinkedAccountsFromGallery'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      hiddenAddressesFromGallery:
          (json['hiddenAddressesFromGallery'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      playlists: (json['playlists'] as List<dynamic>?)
              ?.map((e) => PlayListModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SettingsDataBackupToJson(SettingsDataBackup instance) =>
    <String, dynamic>{
      'isAnalyticsEnabled': instance.isAnalyticsEnabled,
      'hiddenMainnetTokenIDs': instance.hiddenMainnetTokenIDs,
      'hiddenTestnetTokenIDs': instance.hiddenTestnetTokenIDs,
      'hiddenLinkedAccountsFromGallery':
          instance.hiddenLinkedAccountsFromGallery,
      'hiddenAddressesFromGallery': instance.hiddenAddressesFromGallery,
      'playlists': instance.playlists,
    };
