import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement {
  final String announcementContextId;
  final String title;
  final String body;
  final int createdAt;
  final int announceAt;
  final String type;

  Announcement(
      {required this.announcementContextId,
      required this.title,
      required this.body,
      required this.announceAt,
      required this.createdAt,
      required this.type});

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}

@JsonSerializable()
class AnnouncementPostResponse {
  final int ok;

  AnnouncementPostResponse({required this.ok});

  factory AnnouncementPostResponse.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementPostResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementPostResponseToJson(this);
}
