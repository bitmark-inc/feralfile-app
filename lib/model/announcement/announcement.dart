import 'package:autonomy_flutter/model/customer_support.dart';

class Announcement extends ChatThread {
  final String announcementContentId;
  final String content;
  final Map<String, dynamic> additionalData;
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
        additionalData: (json['additionalData'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
        startedAt: DateTime.parse(json['startedAt']).millisecondsSinceEpoch,
        endedAt: DateTime.parse(json['startedAt']).millisecondsSinceEpoch,
      );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > endedAt;

  @override
  String getListTitle() => 'Announcement';

  @override
  bool isUnread() => false;
}
