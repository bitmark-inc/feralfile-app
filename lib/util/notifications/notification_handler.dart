import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notifications/notification_type.dart';
import 'package:flutter/material.dart';

class NotificationHandler {
  // singleton
  static final NotificationHandler instance = NotificationHandler._();

  NotificationHandler._();

  final AnnouncementService _announcementService =
      injector<AnnouncementService>();

  Future<void> handlePushNotificationClicked(
    BuildContext context,
    AdditionalData additionalData,
  ) async {
    log.info('handlePushNotificationClicked');
    if (additionalData.notificationType != NotificationType.announcement) {
      await _announcementService
          .markAsRead(additionalData.announcementContentId);
      if (!context.mounted) {
        return;
      }
      await additionalData.handleTap(context);
    } else {
      if (!context.mounted) {
        return;
      }
      await showInAppNotifications(
        context,
        additionalData.announcementContentId ?? '',
        additionalData,
      );
    }
  }

  // Future<void> handleInAppNotificationClicked(
  //   BuildContext context,
  //   AdditionalData additionalData,
  // ) async {
  //   log.info('handleInAppNotificationClicked');
  //   await _announcementService.markAsRead(additionalData.announcementContentId);
  //   if (!context.mounted) {
  //     return;
  //   }
  // }

  // Future<void> shouldShowInAppNotification(
  //     BuildContext context,
  //     AdditionalData additionalData,
  //     String id,
  //     PageController? pageController) async {
  //   /// after getting additionalData
  //   await _announcementService.fetchAnnouncements();
  //   if (!context.mounted) {
  //     return;
  //   }
  //   // prepare for handling notification
  //   final shouldShow = await additionalData.prepareAndDidSuccess();
  //   if (!shouldShow || !context.mounted) {
  //     return;
  //   }

  //   await _showInAppNotification(
  //     context,
  //     id,
  //     pageController,
  //     additionalData,
  //   );
  // }

  // Future<void> _showInAppNotification(
  //   BuildContext context,
  //   String id,
  //   PageController? pageController,
  //   AdditionalData additionalData,
  // ) async {
  //   final announcement = _announcementService
  //       .getAnnouncement(additionalData.announcementContentId);
  //   if (announcement?.read == true) {
  //     return;
  //   }

  //   if (announcement?.isExpired == true) {
  //     await _announcementService
  //         .markAsRead(announcement?.announcementContentId);
  //     await _announcementService.showOldestAnnouncement();
  //     return;
  //   }

  //   await showInAppNotifications(
  //     context,
  //     id,
  //     additionalData,
  //     body: announcement?.content ?? '',
  //     receivedTime: announcement?.startedAt,
  //     handler: additionalData.isTappable
  //         ? () async {
  //             await handleInAppNotificationClicked(
  //               context,
  //               additionalData,
  //             );
  //           }
  //         : null,
  //     callBackOnDismiss: () async {
  //       await _announcementService.showOldestAnnouncement();
  //     },
  //   );
  // }
}
