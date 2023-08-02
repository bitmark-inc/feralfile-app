import 'package:collection/collection.dart';

class WCPeerMeta {
  final String name;
  final String url;
  final String? description;
  final List<String> icons;
  WCPeerMeta({
    required this.name,
    required this.url,
    required this.description,
    this.icons = const [],
  });

  factory WCPeerMeta.fromJson(Map<String, dynamic> json) =>
      _$WCPeerMetaFromJson(json);

  Map<String, dynamic> toJson() => _$WCPeerMetaToJson(this);

  @override
  String toString() {
    return 'WCPeerMeta(name: $name, url: $url, description: $description, icons: $icons)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is WCPeerMeta &&
        other.name == name &&
        other.url == url &&
        other.description == description &&
        listEquals(other.icons, icons);
  }

  @override
  int get hashCode {
    return name.hashCode ^ url.hashCode ^ description.hashCode ^ icons.hashCode;
  }
}
WCPeerMeta _$WCPeerMetaFromJson(Map<String, dynamic> json) => WCPeerMeta(
  name: json['name'] as String,
  url: json['url'] as String,
  description: json['description'] as String?,
  icons:
  (json['icons'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$WCPeerMetaToJson(WCPeerMeta instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'description': instance.description,
      'icons': instance.icons,
    };