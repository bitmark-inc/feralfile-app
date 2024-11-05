//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  galleryNewNft,
  newPostcardTrip,
  postcardShareExpired,
  customerSupportNewMessage,
  customerSupportCloseIssue,
  artworkCreated,
  artworkReceived,
  newMessage,
  jgCrystallineWorkHasArrived,
  jgCrystallineWorkGenerated,
  exhibitionViewingOpening,
  exhibitionSalesOpening,
  exhibitionSaleClosing,
  navigate,
  general,
  daily,
  ;

  // toString method
  @override
  String toString() {
    switch (this) {
      case NotificationType.galleryNewNft:
        return 'gallery_new_nft';
      case NotificationType.newPostcardTrip:
        return 'new_postcard_trip';
      case NotificationType.postcardShareExpired:
        return 'postcard_share_expired';
      case NotificationType.customerSupportNewMessage:
        return 'customer_support_new_message';
      case NotificationType.customerSupportCloseIssue:
        return 'customer_support_close_issue';
      case NotificationType.artworkCreated:
        return 'artwork_created';
      case NotificationType.artworkReceived:
        return 'artwork_received';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.jgCrystallineWorkHasArrived:
        return 'jg_artwork_solar_day_arrived';
      case NotificationType.jgCrystallineWorkGenerated:
        return 'jg_artwork_generated';
      case NotificationType.exhibitionViewingOpening:
        return 'exhibition_view_opening';
      case NotificationType.exhibitionSalesOpening:
        return 'exhibition_sale_opening';
      case NotificationType.exhibitionSaleClosing:
        return 'exhibition_sale_closing';
      case NotificationType.navigate:
        return 'navigate';
      case NotificationType.general:
        return 'general';
      case NotificationType.daily:
        return 'daily';
    }
  }

  // fromString method
  static NotificationType fromString(String value) {
    switch (value) {
      case 'gallery_new_nft':
        return NotificationType.galleryNewNft;
      case 'new_postcard_trip':
        return NotificationType.newPostcardTrip;
      case 'postcard_share_expired':
        return NotificationType.postcardShareExpired;
      case 'customer_support_new_message':
        return NotificationType.customerSupportNewMessage;
      case 'customer_support_close_issue':
        return NotificationType.customerSupportCloseIssue;
      case 'artwork_created':
        return NotificationType.artworkCreated;
      case 'artwork_received':
        return NotificationType.artworkReceived;
      case 'new_message':
        return NotificationType.newMessage;
      case 'jg_artwork_solar_day_arrived':
        return NotificationType.jgCrystallineWorkHasArrived;
      case 'jg_artwork_generated':
        return NotificationType.jgCrystallineWorkGenerated;
      case 'exhibition_view_opening':
        return NotificationType.exhibitionViewingOpening;
      case 'exhibition_sale_opening':
        return NotificationType.exhibitionSalesOpening;
      case 'exhibition_sale_closing':
        return NotificationType.exhibitionSaleClosing;
      case 'navigate':
        return NotificationType.navigate;
      case 'daily':
        return NotificationType.daily;
      default:
        return NotificationType.general;
    }
  }
}

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
