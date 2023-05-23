// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editorial.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Editorial _$EditorialFromJson(Map<String, dynamic> json) => Editorial(
      editorial: (json['editorial'] as List<dynamic>)
          .map((e) => EditorialPost.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EditorialToJson(Editorial instance) => <String, dynamic>{
      'editorial': instance.editorial,
    };

EditorialPost _$EditorialPostFromJson(Map<String, dynamic> json) =>
    EditorialPost(
      type: json['type'] as String,
      publisher: Publisher.fromJson(json['publisher'] as Map<String, dynamic>),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      content: json['content'] as Map<String, dynamic>,
      reference: json['reference'] == null
          ? null
          : Reference.fromJson(json['reference'] as Map<String, dynamic>),
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$EditorialPostToJson(EditorialPost instance) =>
    <String, dynamic>{
      'type': instance.type,
      'publisher': instance.publisher,
      'publishedAt': instance.publishedAt?.toIso8601String(),
      'content': instance.content,
      'reference': instance.reference,
      'tag': instance.tag,
    };

Publisher _$PublisherFromJson(Map<String, dynamic> json) => Publisher(
      name: json['name'] as String,
      icon: json['icon'] as String,
      intro: json['intro'] as String?,
    );

Map<String, dynamic> _$PublisherToJson(Publisher instance) => <String, dynamic>{
      'name': instance.name,
      'icon': instance.icon,
      'intro': instance.intro,
    };

Reference _$ReferenceFromJson(Map<String, dynamic> json) => Reference(
      location: json['location'] as String,
      website: json['website'] as String,
      socials: (json['socials'] as List<dynamic>)
          .map((e) => Social.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReferenceToJson(Reference instance) => <String, dynamic>{
      'location': instance.location,
      'website': instance.website,
      'socials': instance.socials,
    };

Social _$SocialFromJson(Map<String, dynamic> json) => Social(
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$SocialToJson(Social instance) => <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
    };
