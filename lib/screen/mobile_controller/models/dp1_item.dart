import 'package:autonomy_flutter/screen/mobile_controller/models/provenance.dart';

class DP1Item {
  DP1Item({
    required this.duration,
    required this.provenance,
    this.title,
    this.source,
    this.license,
  }); // e.g., "open", "restricted", etc.

// from JSON
  factory DP1Item.fromJson(Map<String, dynamic> json) {
    return DP1Item(
      title: json['title'] as String?,
      source: json['source'] as String?,
      duration: json['duration'] as int,
      license: json['license'] == null
          ? null
          : ArtworkDisplayLicense.fromString(
              json['license'] as String,
            ),
      provenance: DP1Provenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map),
      ),
    );
  }

  final String? title;
  final String? source;
  final int duration; // in seconds
  final ArtworkDisplayLicense? license;
  final DP1Provenance provenance;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'duration': duration,
      'license': license?.value,
      'provenance': provenance.toJson(),
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

extension DP1PlaylistItemExt on DP1Item {
  String get indexId => provenance.indexId;
}
