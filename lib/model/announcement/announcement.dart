class Announcement {
  final String announcementContentId;
  final String content;
  final dynamic additionalData;
  final int startedAt;
  final int endedAt;

  Announcement({
    required this.announcementContentId,
    required this.content,
    required this.additionalData,
    required this.startedAt,
    required this.endedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        announcementContentId: json['announcementContentID'],
        content: json['content'],
        additionalData: json['additionalData'],
        startedAt: DateTime.parse(json['startedAt']).millisecondsSinceEpoch,
        endedAt: DateTime.parse(json['startedAt']).millisecondsSinceEpoch,
      );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > endedAt;
}
