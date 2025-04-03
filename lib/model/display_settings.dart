import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';

class DisplaySettings implements SettingObject {
  DisplaySettings({
    required this.tokenId,
    required this.setting,
  });

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      DisplaySettings(
        tokenId: json['tokenId'] != null ? json['tokenId'] as String : '',
        setting: ArtistDisplaySetting.fromJson(json),
      );
  final String tokenId;
  final ArtistDisplaySetting setting;

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        ...setting.toJson(),
      };

  @override
  String get key => tokenId;

  @override
  String get value => jsonEncode(toJson());

  @override
  Map<String, String> get toKeyValue => {
        'key': key,
        'value': value,
      };
}
