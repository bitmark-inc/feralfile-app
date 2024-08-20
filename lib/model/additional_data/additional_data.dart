import 'package:autonomy_flutter/model/additional_data/cs_view_thread.dart';
import 'package:autonomy_flutter/model/additional_data/gift_membership.dart';
import 'package:autonomy_flutter/model/additional_data/jg_crystalline_work_generated.dart';
import 'package:autonomy_flutter/model/additional_data/navigation_path.dart';
import 'package:autonomy_flutter/model/additional_data/view_collection.dart'
    as view_collection_handler;
import 'package:autonomy_flutter/model/additional_data/view_exhibition.dart';
import 'package:autonomy_flutter/model/additional_data/view_new_message.dart';
import 'package:autonomy_flutter/model/additional_data/view_postcard.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_type.dart';
import 'package:flutter/cupertino.dart';

class AdditionalData {
  final NotificationType notificationType;
  final String? announcementContentId;

  AdditionalData({
    required this.notificationType,
    this.announcementContentId,
  });

  bool get isTappable => false;

  static AdditionalData fromJson(Map<String, dynamic> json,
      {String? type, String? announcementId}) {
    final notificationType =
        NotificationType.fromString(type ?? json['notification_type']);
    final announcementContentId = announcementId ??
        json['announcementContentID'];

    final parentObject = AdditionalData(
        notificationType: notificationType,
        announcementContentId: announcementContentId);

    switch (notificationType) {
      case NotificationType.customerSupportNewMessage:
      case NotificationType.customerSupportCloseIssue:
        final issueId = json['issue_id'];
        if (issueId == null) {
          log.warning('AdditionalData: issueId is null');
          return parentObject;
        }
        return CsViewThread(
          issueId: issueId,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.artworkCreated:
      case NotificationType.artworkReceived:
      case NotificationType.galleryNewNft:
        return view_collection_handler.ViewCollection(
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.newMessage:
        final groupId = json['group_id'];
        if (groupId == null) {
          log.warning('AdditionalData: groupId is null');
          return parentObject;
        }
        return ViewNewMessage(
          groupId: groupId,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.newPostcardTrip:
      case NotificationType.postcardShareExpired:
        final indexID = json['indexID'];
        if (indexID == null) {
          log.warning('AdditionalData: indexID is null');
          return parentObject;
        }
        return ViewPostcard(
          indexID: indexID,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.jgCrystallineWorkHasArrived:
        final jgExhibitionId = JohnGerrardHelper.exhibitionID;
        return ViewExhibition(
          exhibitionId: jgExhibitionId ?? '',
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.jgCrystallineWorkGenerated:
        final tokenId = json['token_id'];
        if (tokenId == null) {
          log.warning('AdditionalData: tokenId is null');
          return parentObject;
        }
        return JgCrystallineWorkGenerated(
          tokenId: tokenId,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.exhibitionViewingOpening:
      case NotificationType.exhibitionSalesOpening:
      case NotificationType.exhibitionSaleClosing:
        final exhibitionId = json['exhibition_id'];
        if (exhibitionId == null) {
          log.warning('AdditionalData: exhibitionId is null');
          return parentObject;
        }
        return ViewExhibition(
          exhibitionId: exhibitionId,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.giftMembership:
        final giftCode = json['gift_code'];
        return GiftMembership(
          giftCode: giftCode,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
        );
      case NotificationType.navigate:
        final navigationRoute = json['navigation_route'];
        final homeIndex = json['home_index'];
        return NavigationPath(
          navigationRoute: navigationRoute,
          notificationType: notificationType,
          announcementContentId: announcementContentId,
          homeIndex: homeIndex,
        );
      default:
        return parentObject;
    }
  }

  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('AdditionalData: handle tap: $notificationType');
  }

  Future<bool> prepareBeforeShowing() async => true;
}
