import 'package:autonomy_flutter/model/announcement/announcement.dart';
import 'package:autonomy_flutter/model/announcement/announcement_local.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';

class MockAnnouncementService implements AnnouncementService {
  @override
  Future<List<Announcement>> fetchAnnouncements() {
    // TODO: implement fetchAnnouncements
    throw UnimplementedError();
  }

  @override
  Announcement? findAnnouncementByIssueId(String issueId) {
    // TODO: implement findAnnouncementByIssueId
    throw UnimplementedError();
  }

  @override
  String? findIssueIdByAnnouncement(String announcementContentId) {
    // TODO: implement findIssueIdByAnnouncement
    throw UnimplementedError();
  }

  @override
  AnnouncementLocal? getAnnouncement(String? announcementContentId) {
    // TODO: implement getAnnouncement
    throw UnimplementedError();
  }

  @override
  List<AnnouncementLocal> getLocalAnnouncements() {
    // TODO: implement getLocalAnnouncements
    throw UnimplementedError();
  }

  @override
  void linkAnnouncementToIssue(String announcementContentId, String issueId) {
    // TODO: implement linkAnnouncementToIssue
  }

  @override
  Future<void> markAsRead(String? announcementContentId) {
    // TODO: implement markAsRead
    throw UnimplementedError();
  }

  @override
  Future<void> showOldestAnnouncement({bool shouldRepeat = true}) {
    // TODO: implement showOldestAnnouncement
    throw UnimplementedError();
  }
}
