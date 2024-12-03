import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class ChatNotificationData extends AdditionalData {
  ChatNotificationData({
    required super.notificationType,
    super.announcementContentId,
    super.cta,
    super.title,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('ChatNotificationData: handle tap');
    if (announcementContentId != null) {
      final announcement = injector<AnnouncementService>()
          .getAnnouncement(announcementContentId);
      if (announcement != null) {
        await injector<NavigationService>().navigateTo(
          AppRouter.supportThreadPage,
          arguments: NewIssueFromAnnouncementPayload(
            announcement: announcement,
            title: title,
          ),
        );
      } else {
        log.info('[ChatNotificationData] Announcement is not existed');
      }
    }
  }
}
