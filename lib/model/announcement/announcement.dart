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
        startedAt: json['startedAt'],
        endedAt: json['endedAt'],
      );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > endedAt;
}
