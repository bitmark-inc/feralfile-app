import 'package:autonomy_flutter/screen/mobile_controller/dp1_call_request.dart';

class FFDirectory {
  FFDirectory(
    this.name, {
    this.description,
    this.url,
  });

  final String name;
  final String? description;
  final String? url;
}

// extension
extension DirectoryListExtension on FFDirectory {
  bool get isFeralFile {
    return name == 'Feral File';
  }
}

class DP1Artist {
  DP1Artist({
    required this.name,
    required this.relevanceScore,
  }); // e.g., 1.0

  // from JSON
  factory DP1Artist.fromJson(Map<String, dynamic> json) {
    return DP1Artist(
      name: json['name'] as String,
      relevanceScore: (json['relevance_score'] as num).toDouble(),
    );
  }

  final String name;
  final double relevanceScore;

  // to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relevance_score': relevanceScore,
    };
  }
}

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

class PlaylistDP1Call implements DP1CallBase {
  PlaylistDP1Call({
    required this.dpVersion,
    required this.id,
    required this.created,
    required this.defaults,
    required this.items,
    required this.signature,
  }); // e.g., "ed25519:0x884e6b4bab7ab8"

  // from JSON
  factory PlaylistDP1Call.fromJson(Map<String, dynamic> json) {
    return PlaylistDP1Call(
      dpVersion: json['dpVersion'] as String,
      id: json['id'] as String,
      created: DateTime.parse(json['created'] as String),
      defaults: json['defaults'] as Map<String, dynamic>,
      items: (json['items'] as List<dynamic>)
          .map((e) => DP1PlaylistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      signature: json['signature'] as String,
    );
  }

  final String dpVersion; // e.g., "1.0.0"
  final String id; // e.g., "refik-anadol-20250626T063826"
  final DateTime created; // e.g., "2025-06-26T06:38:26.396Z"
  final Map<String, dynamic> defaults; // e.g., {"display": {...}}
  final List<DP1PlaylistItem> items; // list of DP1PlaylistItem
  final String signature;

  // to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'dpVersion': dpVersion,
      'id': id,
      'created': created.toIso8601String(),
      'defaults': defaults,
      'items': items.map((e) => e.toJson()).toList(),
      'signature': signature,
    };
  }
}

enum ArtworkDisplayLicense {
  open,
  restricted;

  String get value {
    switch (this) {
      case ArtworkDisplayLicense.open:
        return 'open';
      case ArtworkDisplayLicense.restricted:
        return 'restricted';
    }
  }

  static ArtworkDisplayLicense fromString(String value) {
    switch (value) {
      case 'open':
        return ArtworkDisplayLicense.open;
      case 'restricted':
        return ArtworkDisplayLicense.restricted;
      default:
        throw ArgumentError('Unknown license type: $value');
    }
  }
}

class DP1PlaylistItem {
  DP1PlaylistItem({
    required this.id,
    required this.title,
    required this.source,
    required this.duration,
    required this.license,
  }); // e.g., "open", "restricted", etc.

// from JSON
  factory DP1PlaylistItem.fromJson(Map<String, dynamic> json) {
    return DP1PlaylistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String,
      duration: json['duration'] as int,
      license: ArtworkDisplayLicense.fromString(
        json['license'] as String,
      ),
    );
  }

  final String id;
  final String title;
  final String source;
  final int duration; // in seconds
  final ArtworkDisplayLicense license;

  // to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'duration': duration,
      'license': license.value,
    };
  }
}

class ArtworkProvenance {}
