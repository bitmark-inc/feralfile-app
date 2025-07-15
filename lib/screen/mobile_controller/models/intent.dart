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

enum DPIEntityType {
  artist;

  String get value {
    switch (this) {
      case DPIEntityType.artist:
        return 'artist';
    }
  }

  static DPIEntityType fromString(String value) {
    switch (value) {
      case 'artist':
        return DPIEntityType.artist;
      default:
        throw ArgumentError('Unknown entity type: $value');
    }
  }
}

class DPEntity {
  DPEntity({
    required this.name,
    required this.type,
    required this.probability,
    this.slug,
  });

  factory DPEntity.fromJson(Map<String, dynamic> json) {
    return DPEntity(
      name: json['name'] as String,
      type: DPIEntityType.fromString(json['type'] as String),
      probability: (json['probability'] as num).toDouble(),
      slug: json['slug'] as String?,
    );
  }

  final String name;
  final DPIEntityType type;
  final double probability;
  final String? slug;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.value,
      'probability': probability,
      'slug': slug,
    };
  }
}

class DP1Intent {
  DP1Intent({
    required this.action,
    this.deviceName,
    this.entities,
    this.searchTerm,
  });

  DP1Intent.displayNow({this.deviceName, this.entities, this.searchTerm})
      : action = DP1Action.now;

  DP1Intent.schedulePlay({this.deviceName, this.entities, this.searchTerm})
      : action = DP1Action.schedulePlay;

  factory DP1Intent.fromJson(Map<String, dynamic> json) {
    return DP1Intent(
      action: DP1Action.fromString(json['action'] as String),
      deviceName: json['device_name'] as String?,
      entities: json['entities'] == null
          ? null
          : (json['entities'] as List<dynamic>)
              .map((e) => DPEntity.fromJson(e as Map<String, dynamic>))
              .toList(),
      searchTerm: json['search_term'] as String?,
    );
  }

  final DP1Action action;
  final String? deviceName;
  final List<DPEntity>? entities;
  final String? searchTerm;

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      'device_name': deviceName,
      'entities': entities?.map((e) => e.toJson()).toList(),
      'search_term': searchTerm,
    };
  }

  String get displayText {
    String prefix = 'Finding artworks';
    if (action == DP1Action.now) {
      prefix = 'Getting artworks';
    } else if (action == DP1Action.schedulePlay) {
      prefix = 'Preparing artworks for scheduled play';
    }

    if (entities != null && entities!.isNotEmpty) {
      final artistNames = entities!.map((e) => e.name).join(', ');
      return '$prefix for artist(s) $artistNames';
    } else if (searchTerm != null && searchTerm!.isNotEmpty) {
      return '$prefix for "$searchTerm"';
    } else {
      return '$prefix';
    }
  }
}
