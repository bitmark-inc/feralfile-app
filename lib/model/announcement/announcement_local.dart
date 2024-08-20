import 'package:autonomy_flutter/model/announcement/announcement.dart';

class AnnouncementLocal extends Announcement {
  bool read;

  AnnouncementLocal({
    required super.announcementContentId,
    required super.content,
    required super.additionalData,
    required super.startedAt,
    required super.endedAt,
    this.read = false,
  });

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
      );
}
