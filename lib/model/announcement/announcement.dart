import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:easy_localization/easy_localization.dart';

class Announcement extends ChatThread {
  final String announcementContentId;
  final String content;
  final Map<String, dynamic> additionalData;
  final DateTime startedAt;
  final DateTime endedAt;

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
        startedAt: DateTime.parse(json['startedAt']),
        endedAt: DateTime.parse(json['endedAt']),
      );

  bool get isExpired => DateTime.now().isAfter(endedAt);

  @override
  String getListTitle() => 'chat_with_feralfile'.tr();

  @override
  bool isUnread() => false;

  @override
  DateTime get sortTime => startedAt;
}
