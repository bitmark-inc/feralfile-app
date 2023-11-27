import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement {
  @JsonKey(name: 'announcement_context_id')
  final String announcementContextId;
  final String title;
  final String body;
  @JsonKey(name: 'created_at')
  final int createdAt;
  @JsonKey(name: 'announce_at')
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
