import 'package:autonomy_flutter/screen/mobile_controller/models/artist.dart';

enum DP1Action {
  now,
  schedulePlay;

  String get value {
    switch (this) {
      case DP1Action.now:
        return 'now_display';
      case DP1Action.schedulePlay:
        return 'schedule_play';
    }
  }

  static DP1Action fromString(String value) {
    switch (value) {
      case 'now_display':
        return DP1Action.now;
      case 'schedule_play':
        return DP1Action.schedulePlay;
      default:
        throw ArgumentError('Unknown action type: $value');
    }
  }
}

abstract class DP1IntentBase {
  Map<String, dynamic> toJson();
}

class DP1Intent implements DP1IntentBase {
  DP1Intent({
    required this.action,
    this.deviceName,
    this.artists,
  }); // e.g., [{"name": "Refik Anadol", "relevance_score": 1}]

  // constructor .displayNow
  DP1Intent.displayNow({this.deviceName, this.artists})
      : action = DP1Action.now;

  // constructor .schedulePlay
  DP1Intent.schedulePlay({this.deviceName, this.artists})
      : action = DP1Action.schedulePlay;

  // from JSON
  factory DP1Intent.fromJson(Map<String, dynamic> json) {
    return DP1Intent(
      action: DP1Action.fromString(json['action'] as String),
      deviceName: json['device_name'] as String?,
      artists: json['artist'] == null
          ? null
          : (json['artist'] as List<dynamic>)
              .map((e) => DP1Artist.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  final DP1Action action;
  final String? deviceName; // e.g., "kitchen"
  final List<DP1Artist>? artists;

  // to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      'device_name': deviceName,
      'artist': artists?.map((e) => e.toJson()).toList(),
    };
  }
}
