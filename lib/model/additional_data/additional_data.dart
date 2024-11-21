import 'dart:async';

import 'package:autonomy_flutter/model/additional_data/announcement_data.dart';
import 'package:autonomy_flutter/model/additional_data/call_to_action.dart';
import 'package:autonomy_flutter/model/additional_data/chat_notification_data.dart';
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
  final NotificationType notificationType;
  final String? announcementContentId;
  final String? title;
  final CallToAction? cta;
  final List<CallToAction>? listCustomCta;

  AdditionalData({
    required this.notificationType,
    this.announcementContentId,
    this.cta,
    this.title,
    this.listCustomCta,
  });

  bool get isTappable => false;

  static AdditionalData fromJson(Map<String, dynamic> json, {String? type}) {
    final notificationContentId = json['notification_content_id'];
    try {
      final notificationType =
          NotificationType.fromString(type ?? json['notification_type']);
      final String? title = json['title'];
      final cta = json['cta'] == null
          ? null
          : CallToAction.fromJson(Map<String, dynamic>.from(json['cta']));

      final defaultAdditionalData = AdditionalData(
        notificationType: notificationType,
        announcementContentId: notificationContentId,
        cta: cta,
        title: title,
      );

      switch (notificationType) {
        case NotificationType.supportMessage:
          return ChatNotificationData(
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
            title: title,
          );
        case NotificationType.dailyArtworkReminders:
          return DailyNotificationData(
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.announcement:
          final listCustomCta = json['custom_data'] != null &&
                  json['custom_data']['button_cta_list'] != null
              ? (json['custom_data']['button_cta_list'] as List)
                  .map((e) =>
                      CallToAction.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : null;

          return AnnouncementData(
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
            title: title,
            listCustomCta: listCustomCta,
          );

        case NotificationType.customerSupportNewMessage:
        case NotificationType.customerSupportCloseIssue:
          final issueId = json['issue_id'];
          if (issueId == null) {
            log.warning('AdditionalData: issueId is null');
            return defaultAdditionalData;
          }
          return CsViewThread(
            issueId: issueId.toString(),
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.artworkCreated:
        case NotificationType.artworkReceived:
        case NotificationType.galleryNewNft:
          return view_collection_handler.ViewCollection(
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.newMessage:
          final groupId = json['group_id'];
          if (groupId == null) {
            log.warning('AdditionalData: groupId is null');
            return defaultAdditionalData;
          }
          return ViewNewMessage(
            groupId: groupId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.newPostcardTrip:
        case NotificationType.postcardShareExpired:
          final indexID = json['indexID'];
          if (indexID == null) {
            log.warning('AdditionalData: indexID is null');
            return defaultAdditionalData;
          }
          return ViewPostcard(
            indexID: indexID,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.jgCrystallineWorkHasArrived:
          final jgExhibitionId = JohnGerrardHelper.exhibitionID;
          return ViewExhibitionData(
            exhibitionId: jgExhibitionId ?? '',
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.jgCrystallineWorkGenerated:
          final tokenId = json['token_id'];
          if (tokenId == null) {
            log.warning('AdditionalData: tokenId is null');
            return defaultAdditionalData;
          }
          return JgCrystallineWorkGenerated(
            tokenId: tokenId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.exhibitionViewingOpening:
        case NotificationType.exhibitionSalesOpening:
        case NotificationType.exhibitionSaleClosing:
          final exhibitionId = json['exhibition_id'];
          if (exhibitionId == null) {
            log.warning('AdditionalData: exhibitionId is null');
            return defaultAdditionalData;
          }
          return ViewExhibitionData(
            exhibitionId: exhibitionId,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            cta: cta,
          );
        case NotificationType.navigate:
          final navigationRoute = json['navigation_route'];
          final homeIndex = json['home_index'];
          return NavigateAdditionalData(
            navigationRoute: navigationRoute,
            notificationType: notificationType,
            announcementContentId: notificationContentId,
            homeIndex: homeIndex,
            cta: cta,
          );

        default:
          return defaultAdditionalData;
      }
    } catch (_) {
      log.info('AdditionalData: error parsing additional data');
      return AdditionalData(
          notificationType: NotificationType.general,
          announcementContentId: notificationContentId);
    }
  }

  Future<void> handleTap(BuildContext context) async {
    log.info('AdditionalData: handle tap: $notificationType');
  }

  FutureOr<bool> prepareAndDidSuccess() => true;
}
