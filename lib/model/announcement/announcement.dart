import 'package:autonomy_flutter/model/announcement/notification_setting_type.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:easy_localization/easy_localization.dart';

class Announcement extends ChatThread {
  final String announcementContentId;
  final String content;
  final Map<String, dynamic> additionalData;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? imageURL;
  final String? notificationType;
  final String? deliveryTimeOfDay;
  final bool inAppEnabled;

  Announcement({
    required this.announcementContentId,
    required this.content,
    required this.additionalData,
    required this.startedAt,
    required this.endedAt,
    required this.inAppEnabled,
    required this.notificationType,
    this.imageURL,
    this.deliveryTimeOfDay,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        announcementContentId: json['notificationContentID'],
        content: json['content'],
        additionalData: (json['additionalData'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
        startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
        endedAt: DateTime.tryParse(json['endedAt'] ?? '') ??
            DateTime.now().add(const Duration(days: 365)),
        imageURL: json['imageURL'],
        notificationType: json['notificationType'],
        deliveryTimeOfDay: json['deliveryTimeOfDay'],
        inAppEnabled: json['inAppEnabled'],
      );

  bool get isExpired => DateTime.now().isAfter(endedAt);

  @override
  String getListTitle() => 'chat_with_feralfile'.tr();

  @override
  bool isUnread() => false;

  @override
  DateTime get sortTime => startedAt;

  NotificationSettingType? get notificationSettingType =>
      NotificationSettingType.fromString(notificationType ?? '');
}
