import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';

class DisplaySettings {
  DisplaySettings({
    required this.viewMode,
    required this.rotationAngle,
  });
  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      DisplaySettings(
        viewMode: ArtFraming.values[json['viewMode'] as int],
        rotationAngle: json['rotationAngle'] as int,
      );
  final ArtFraming viewMode;
  final int rotationAngle;

  Map<String, dynamic> toJson() => {
        'viewMode': viewMode.index,
        'rotationAngle': rotationAngle,
      };

  static final defaultSettings = DisplaySettings(
    viewMode: ArtFraming.fitToScreen,
    rotationAngle: 0,
  );
}
