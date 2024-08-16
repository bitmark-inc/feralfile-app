import 'package:autonomy_flutter/model/additional_data/cs_view_thread.dart';
import 'package:autonomy_flutter/model/additional_data/jg_crystalline_work_generated.dart';
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

  AdditionalData({required this.notificationType});

  static AdditionalData fromJson(Map<String, dynamic> json, {String? type}) {
    final notificationType =
        NotificationType.fromString(type ?? json['notification_type']);

    switch (notificationType) {
      case NotificationType.customerSupportNewMessage:
      case NotificationType.customerSupportCloseIssue:
        final issueId = json['issue_id'];
        if (issueId == null) {
          log.warning('AdditionalData: issueId is null');
          return AdditionalData(notificationType: notificationType);
        }
        return CsViewThread(
            issueId: issueId, notificationType: notificationType);
      case NotificationType.artworkCreated:
      case NotificationType.artworkReceived:
      case NotificationType.galleryNewNft:
        return view_collection_handler.ViewCollection(
            notificationType: notificationType);
      case NotificationType.newMessage:
        final groupId = json['group_id'];
        if (groupId == null) {
          log.warning('AdditionalData: groupId is null');
          return AdditionalData(notificationType: notificationType);
        }
        return ViewNewMessage(
            groupId: groupId, notificationType: notificationType);
      case NotificationType.newPostcardTrip:
      case NotificationType.postcardShareExpired:
        final indexID = json['indexID'];
        if (indexID == null) {
          log.warning('AdditionalData: indexID is null');
          return AdditionalData(notificationType: notificationType);
        }
        return ViewPostcard(
            indexID: indexID, notificationType: notificationType);
      case NotificationType.jgCrystallineWorkHasArrived:
        final jgExhibitionId = JohnGerrardHelper.exhibitionID;
        return ViewExhibition(
            exhibitionId: jgExhibitionId ?? '',
            notificationType: notificationType);
      case NotificationType.jgCrystallineWorkGenerated:
        final tokenId = json['token_id'];
        if (tokenId == null) {
          log.warning('AdditionalData: tokenId is null');
          return AdditionalData(notificationType: notificationType);
        }
        return JgCrystallineWorkGenerated(
            tokenId: tokenId, notificationType: notificationType);
      case NotificationType.exhibitionViewingOpening:
      case NotificationType.exhibitionSalesOpening:
      case NotificationType.exhibitionSaleClosing:
        final exhibitionId = json['exhibition_id'];
        if (exhibitionId == null) {
          log.warning('AdditionalData: exhibitionId is null');
          return AdditionalData(notificationType: notificationType);
        }
        return ViewExhibition(
            exhibitionId: exhibitionId, notificationType: notificationType);
      default:
        return AdditionalData(notificationType: notificationType);
    }
  }

  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('AdditionalData: handle tap: $notificationType');
  }
}
