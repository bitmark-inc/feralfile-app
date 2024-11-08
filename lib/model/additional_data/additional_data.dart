import 'dart:async';

import 'package:autonomy_flutter/model/additional_data/cs_view_thread.dart';
import 'package:autonomy_flutter/model/additional_data/daily_notification_data.dart';
import 'package:autonomy_flutter/model/additional_data/jg_crystalline_work_generated.dart';
import 'package:autonomy_flutter/model/additional_data/navigate_additional_data.dart';
import 'package:autonomy_flutter/model/additional_data/view_collection.dart'
    as view_collection_handler;
import 'package:autonomy_flutter/model/additional_data/view_exhibition.dart';
import 'package:autonomy_flutter/model/additional_data/view_new_message.dart';
import 'package:autonomy_flutter/model/additional_data/view_postcard.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notifications/notification_type.dart';
import 'package:flutter/cupertino.dart';

class AdditionalData {
  final NotificationDataType notificationType;
  final String? announcementContentId;
  final String? linkText;

  AdditionalData({
    required this.notificationType,
    this.announcementContentId,
    this.linkText,
  });

  bool get isTappable => false;

  static AdditionalData fromJson(Map<String, dynamic> json, {String? type}) {
    final notificationContentId = json['notification_content_id'];
    try {
      final notificationType =
          NotificationDataType.fromString(type ?? json['notification_type']);
      final String? linkText = json['link_text'];

      final defaultAdditionalData = AdditionalData(
        notificationType: notificationType,
        announcementContentId: notificationContentId,
        linkText: linkText,
      );

      switch (notificationType) {
        case NotificationDataType.customerSupportNewMessage:
        case NotificationDataType.customerSupportCloseIssue:
          final issueId = json['issue_id'];
          if (issueId == null) {
            log.warning('AdditionalData: issueId is null');
            return defaultAdditionalData;
          }
          return CsViewThread(
            issueId: issueId.toString(),
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.artworkCreated:
        case NotificationDataType.artworkReceived:
        case NotificationDataType.galleryNewNft:
          return view_collection_handler.ViewCollection(
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.newMessage:
          final groupId = json['group_id'];
          if (groupId == null) {
            log.warning('AdditionalData: groupId is null');
            return defaultAdditionalData;
          }
          return ViewNewMessage(
            groupId: groupId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.newPostcardTrip:
        case NotificationDataType.postcardShareExpired:
          final indexID = json['indexID'];
          if (indexID == null) {
            log.warning('AdditionalData: indexID is null');
            return defaultAdditionalData;
          }
          return ViewPostcard(
            indexID: indexID,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.jgCrystallineWorkHasArrived:
          final jgExhibitionId = JohnGerrardHelper.exhibitionID;
          return ViewExhibitionData(
            exhibitionId: jgExhibitionId ?? '',
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.jgCrystallineWorkGenerated:
          final tokenId = json['token_id'];
          if (tokenId == null) {
            log.warning('AdditionalData: tokenId is null');
            return defaultAdditionalData;
          }
          return JgCrystallineWorkGenerated(
            tokenId: tokenId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.exhibitionViewingOpening:
        case NotificationDataType.exhibitionSalesOpening:
        case NotificationDataType.exhibitionSaleClosing:
          final exhibitionId = json['exhibition_id'];
          if (exhibitionId == null) {
            log.warning('AdditionalData: exhibitionId is null');
            return defaultAdditionalData;
          }
          return ViewExhibitionData(
            exhibitionId: exhibitionId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );
        case NotificationDataType.navigate:
          final navigationRoute = json['navigation_route'];
          final homeIndex = json['home_index'];
          return NavigateAdditionalData(
            navigationRoute: navigationRoute,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            homeIndex: homeIndex,
            linkText: linkText,
          );
        case NotificationDataType.dailyArtworkReminders:
          final subType = json['notification_sub_type'];
          final dailyType = DailyNotificationType.fromString(subType ?? '');
          if (dailyType == null) {
            log.warning('AdditionalData: dailyType is null');
            return defaultAdditionalData;
          }
          return DailyNotificationData(
            dailyNotificationType: dailyType,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            linkText: linkText,
          );

        default:
          return defaultAdditionalData;
      }
    } catch (_) {
      log.info('AdditionalData: error parsing additional data');
      return AdditionalData(
          notificationType: NotificationDataType.general,
          announcementContentId: notificationContentId);
    }
  }

  Future<void> handleTap(BuildContext context) async {
    log.info('AdditionalData: handle tap: $notificationType');
  }

  FutureOr<bool> prepareAndDidSuccess() => true;
}
