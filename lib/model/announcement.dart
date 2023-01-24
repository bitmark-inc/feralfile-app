import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement {
  final String announcementId;
  final String title;
  final String body;
  final int announceAt;
  final String type;

  Announcement(
      {required this.announcementId,
      required this.title,
      required this.body,
      required this.announceAt,
      required this.type});

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}

@JsonSerializable()
class AnnouncementPostResponse {
  final String announcementID;

  AnnouncementPostResponse({required this.announcementID});

  factory AnnouncementPostResponse.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementPostResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementPostResponseToJson(this);
}
