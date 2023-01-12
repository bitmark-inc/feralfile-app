// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      announcementId: json['announcementId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      announceAt: json['announceAt'] as int,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'announcementId': instance.announcementId,
      'title': instance.title,
      'body': instance.body,
      'announceAt': instance.announceAt,
      'type': instance.type,
    };

AnnouncementPostResponse _$AnnouncementPostResponseFromJson(
        Map<String, dynamic> json) =>
    AnnouncementPostResponse(
      announcementID: json['announcementID'] as String,
    );

Map<String, dynamic> _$AnnouncementPostResponseToJson(
        AnnouncementPostResponse instance) =>
    <String, dynamic>{
      'announcementID': instance.announcementID,
    };
