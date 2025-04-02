import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:flutter/widgets.dart';

class DisplaySettings implements SettingObject {
  DisplaySettings({
    required this.tokenId,
    this.fitment,
    this.orientation,
  });
  const DisplaySettings.defaultSettings(this.tokenId)
      : fitment = ArtFraming.fitToScreen,
        orientation = Orientation.portrait;

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      DisplaySettings(
        tokenId: json['tokenId'] != null ? json['tokenId'] as String : '',
        fitment: json['fitment'] != null &&
                (json['fitment'] as int) < ArtFraming.values.length
            ? ArtFraming.values[json['fitment'] as int]
            : ArtFraming.fitToScreen,
        orientation:
            json['orientation'] as Orientation? ?? Orientation.portrait,
      );
  final ArtFraming? fitment;
  final Orientation? orientation;
  final String tokenId;

  DisplaySettings copyWith({
    ArtFraming? fitment,
    Orientation? orientation,
  }) =>
      DisplaySettings(
        tokenId: tokenId,
        fitment: fitment ?? this.fitment,
        orientation: orientation ?? this.orientation,
      );

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        if (fitment != null) 'fitment': fitment!.index,
        if (orientation != null) 'orientation': orientation!.index,
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
