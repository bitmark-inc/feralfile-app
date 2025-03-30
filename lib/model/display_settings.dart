import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';

class DisplaySettings implements SettingObject {
  DisplaySettings({
    required this.tokenId,
    this.viewMode,
    this.rotationAngle,
  });
  const DisplaySettings.defaultSettings(this.tokenId)
      : viewMode = ArtFraming.fitToScreen,
        rotationAngle = 0;

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      DisplaySettings(
        tokenId: json['tokenId'] != null ? json['tokenId'] as String : '',
        viewMode: json['viewMode'] != null &&
                (json['viewMode'] as int) < ArtFraming.values.length
            ? ArtFraming.values[json['viewMode'] as int]
            : ArtFraming.fitToScreen,
        rotationAngle: json['rotationAngle'] as int? ?? 0,
      );
  final ArtFraming? viewMode;
  final int? rotationAngle;
  final String tokenId;

  DisplaySettings copyWith({
    ArtFraming? viewMode,
    int? rotationAngle,
  }) =>
      DisplaySettings(
        tokenId: tokenId,
        viewMode: viewMode ?? this.viewMode,
        rotationAngle: rotationAngle ?? this.rotationAngle,
      );

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        if (viewMode != null) 'viewMode': viewMode!.index,
        if (rotationAngle != null) 'rotationAngle': rotationAngle,
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
