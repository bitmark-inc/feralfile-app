import 'package:autonomy_flutter/model/announcement/announcement.dart';

class AnnouncementLocal extends Announcement {
  bool read;

  AnnouncementLocal({
    required super.announcementContentId,
    required super.content,
    required super.additionalData,
    required super.startedAt,
    required super.endedAt,
    required super.inAppEnabled,
    this.read = false,
  });

  static AnnouncementLocal addFromAdditionalData({
    required String announcementContentId,
    required String content,
    required Map<String, dynamic> additionalData,
    required DateTime startedAt,
    required DateTime endedAt,
    required bool read,
  }) =>
      AnnouncementLocal(
        announcementContentId: announcementContentId,
        content: content,
        additionalData: additionalData,
        startedAt: startedAt,
        endedAt: endedAt,
        inAppEnabled: additionalData['~inAppEnabled'] ?? true,
        read: read,
      );

  AnnouncementLocal markAsRead() {
    read = true;
    return this;
  }

  static AnnouncementLocal fromAnnouncement(Announcement announcement) =>
      AnnouncementLocal(
        announcementContentId: announcement.announcementContentId,
        content: announcement.content,
        additionalData: announcement.additionalData,
        startedAt: announcement.startedAt,
        endedAt: announcement.endedAt,
        inAppEnabled: announcement.inAppEnabled,
      );

  @override
  bool isUnread() => !read;
}
