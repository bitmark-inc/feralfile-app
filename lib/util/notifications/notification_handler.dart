import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class NotificationHandler {
  // singleton
  static final NotificationHandler instance = NotificationHandler._();

  NotificationHandler._();

  final AnnouncementService _announcementService =
      injector<AnnouncementService>();

  Future<void> handleNotificationClicked(BuildContext context,
      AdditionalData additionalData, String id, String body,
      {String channel = 'push'}) async {
    log.info('Tap to notification: $body ');

    await _announcementService.markAsRead(additionalData.announcementContentId);
    if (!context.mounted) {
      return;
    }
    await additionalData.handleTap(context);
  }

  Future<void> shouldShowNotifications(
      BuildContext context,
      AdditionalData additionalData,
      String id,
      String body,
      PageController? pageController) async {
    /// after getting additionalData
    await _announcementService.fetchAnnouncements();
    if (!context.mounted) {
      return;
    }
    // prepare for handling notification
    final shouldShow = await additionalData.prepareAndDidSuccess();
    if (!shouldShow || !context.mounted) {
      return;
    }

    await _showNotification(context, id, body, pageController, additionalData);
  }

  Future<void> _showNotification(
    BuildContext context,
    String id,
    String body,
    PageController? pageController,
    AdditionalData additionalData,
  ) async {
    final announcement = _announcementService
        .getAnnouncement(additionalData.announcementContentId);
    if (announcement?.read == true) {
      return;
    }
    if (announcement?.isExpired == true) {
      await _announcementService
          .markAsRead(announcement?.announcementContentId);
      await _announcementService.showOldestAnnouncement();
      return;
    }

    await showNotifications(
      context,
      id,
      body: body,
      handler: additionalData.isTappable
          ? () async {
              await handleNotificationClicked(
                context,
                additionalData,
                id,
                body,
                channel: 'in-app',
              );
            }
          : null,
      callBackOnDismiss: () async {
        await _announcementService.showOldestAnnouncement();
      },
      additionalData: additionalData,
    );
  }
}
