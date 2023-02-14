// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      announcementContextId: json['announcement_context_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      announceAt: json['announce_at'] as int,
      createdAt: json['created_at'] as int,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'announcement_context_id': instance.announcementContextId,
      'title': instance.title,
      'body': instance.body,
      'created_at': instance.createdAt,
      'announce_at': instance.announceAt,
      'type': instance.type,
    };

AnnouncementPostResponse _$AnnouncementPostResponseFromJson(
        Map<String, dynamic> json) =>
    AnnouncementPostResponse(
      ok: json['ok'] as int,
    );

Map<String, dynamic> _$AnnouncementPostResponseToJson(
        AnnouncementPostResponse instance) =>
    <String, dynamic>{
      'ok': instance.ok,
    };
