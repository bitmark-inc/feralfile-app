import 'package:autonomy_flutter/screen/mobile_controller/models/provenance.dart';

class DP1PlaylistItem {
  DP1PlaylistItem({
    required this.id,
    required this.title,
    required this.source,
    required this.duration,
    required this.license,
    this.provenance,
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
      provenance: json['provenance'] != null
          ? DP1Provenance.fromJson(
              Map<String, dynamic>.from(json['provenance'] as Map))
          : null,
    );
  }

  final String id;
  final String title;
  final String source;
  final int duration; // in seconds
  final ArtworkDisplayLicense license;
  final DP1Provenance? provenance;

  // to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'duration': duration,
      'license': license.value,
      'provenance': provenance?.toJson(),
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

extension DP1PlaylistItemExt on DP1PlaylistItem {
  String? get indexId => provenance?.indexId;
}
