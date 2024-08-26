//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

enum NotificationType {
  galleryNewNft,
  newPostcardTrip,
  postcardShareExpired,
  customerSupportNewMessage,
  customerSupportCloseIssue,
  customerSupportNewAnnouncement,
  artworkCreated,
  artworkReceived,
  newMessage,
  jgCrystallineWorkHasArrived,
  jgCrystallineWorkGenerated,
  exhibitionViewingOpening,
  exhibitionSalesOpening,
  exhibitionSaleClosing,
  unknown;

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
      case NotificationType.customerSupportNewAnnouncement:
        return 'customer_support_new_announcement';
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
      case NotificationType.unknown:
        return 'unknown';
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
      case 'customer_support_new_announcement':
        return NotificationType.customerSupportNewAnnouncement;
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
      default:
        return NotificationType.unknown;
    }
  }
}

class NotificationHandler {
  // singleton
  static final NotificationHandler instance = NotificationHandler._();

  NotificationHandler._();

  final ConfigurationService _configurationService =
      injector<ConfigurationService>();
  final RemoteConfigService _remoteConfig = injector<RemoteConfigService>();
  final ClientTokenService _clientTokenService = injector<ClientTokenService>();
  final NavigationService _navigationService = injector<NavigationService>();

  Future<void> handleNotificationClicked(BuildContext context,
      OSNotification notification, PageController? pageController) async {
    if (notification.additionalData == null) {
      // Skip handling the notification without data
      return;
    }

    log.info("Tap to notification: ${notification.body ?? "empty"} "
        '\nAdditional data: ${notification.additionalData!}');

    final navigatePath = notification.additionalData!['navigation_route'];
    if (navigatePath != null) {
      await injector<NavigationService>().navigatePath(navigatePath);
    }

    final notificationType = NotificationType.fromString(
        notification.additionalData!['notification_type']);
    if (!context.mounted) {
      return;
    }
    switch (notificationType) {
      case NotificationType.galleryNewNft:
        await _navigationService.popToCollection();

      case NotificationType.customerSupportNewMessage:
      case NotificationType.customerSupportCloseIssue:
        final issueID = '${notification.additionalData!["issue_id"]}';
        final announcement = await injector<CustomerSupportService>()
            .findAnnouncementFromIssueId(issueID);
        if (!context.mounted) {
          return;
        }
        unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.supportThreadPage,
          (route) =>
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition,
          arguments: DetailIssuePayload(
              reportIssueType: '',
              issueID: issueID,
              announcement: announcement),
        ));
      case NotificationType.customerSupportNewAnnouncement:
        final announcementID = '${notification.additionalData!["id"]}';
        unawaited(_openAnnouncement(context, announcementID));

      case NotificationType.artworkCreated:
      case NotificationType.artworkReceived:
        await _navigationService.popToCollection();
      case NotificationType.newMessage:
        if (!_remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
          return;
        }
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final tokenId = data['group_id'];
        final tokens = await injector<NftCollectionDatabase>()
            .assetTokenDao
            .findAllAssetTokensByTokenIDs([tokenId]);
        final owner = tokens.first.owner;
        final isSkip =
            injector<ChatService>().isConnecting(address: owner, id: tokenId);
        if (isSkip) {
          return;
        }
        final GlobalKey<ClaimedPostcardDetailPageState> key = GlobalKey();
        final postcardDetailPayload = PostcardDetailPagePayload(
            [ArtworkIdentity(tokenId, owner)], 0,
            key: key);
        if (!context.mounted) {
          return;
        }
        unawaited(Navigator.of(context).pushNamed(
            AppRouter.claimedPostcardDetailsPage,
            arguments: postcardDetailPayload));
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          final state = key.currentState;
          final assetToken =
              key.currentContext?.read<PostcardDetailBloc>().state.assetToken;
          if (state != null && assetToken != null) {
            unawaited(state.gotoChatThread(key.currentContext!));
            timer.cancel();
          }
        });

      case NotificationType.newPostcardTrip:
      case NotificationType.postcardShareExpired:
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final indexID = data['indexID'];
        final tokens = await injector<NftCollectionDatabase>()
            .assetTokenDao
            .findAllAssetTokensByTokenIDs([indexID]);
        if (tokens.isEmpty) {
          return;
        }
        final owner = tokens.first.owner;
        final postcardDetailPayload = PostcardDetailPagePayload(
          [ArtworkIdentity(indexID, owner)],
          0,
          useIndexer: true,
        );
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        unawaited(Navigator.of(context).pushNamed(
            AppRouter.claimedPostcardDetailsPage,
            arguments: postcardDetailPayload));

      case NotificationType.jgCrystallineWorkHasArrived:
        final jgExhibitionId = JohnGerrardHelper.exhibitionID;
        await _navigationService
            .gotoExhibitionDetailsPage(jgExhibitionId ?? '');

      case NotificationType.jgCrystallineWorkGenerated:
        _navigationService.popUntilHome();
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final tokenId = data['token_id'];
        final indexId = JohnGerrardHelper.getIndexID(tokenId);
        await _navigationService.gotoArtworkDetailsPage(indexId);

      case NotificationType.exhibitionViewingOpening:
      case NotificationType.exhibitionSalesOpening:
      case NotificationType.exhibitionSaleClosing:
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final exhibitionId = data['exhibition_id'];
        await _navigationService.gotoExhibitionDetailsPage(exhibitionId);
      default:
        log.warning('unhandled notification type: $notificationType');
        break;
    }
  }

  Future<void> shouldShowNotifications(BuildContext context,
      OSNotificationReceivedEvent event, PageController? pageController) async {
    log.info('Receive notification: ${event.notification}');
    final data = event.notification.additionalData;
    if (data == null) {
      return;
    }
    if (_configurationService.isNotificationEnabled() != true) {
      _configurationService.showNotifTip.value = true;
    }

    final notificationType =
        NotificationType.fromString(data['notification_type']);

    // prepare for handling notification
    switch (notificationType) {
      case NotificationType.customerSupportNewMessage:
      case NotificationType.customerSupportCloseIssue:
        final notificationIssueID =
            '${event.notification.additionalData?['issue_id']}';
        injector<CustomerSupportService>().triggerReloadMessages.value += 1;
        unawaited(
            injector<CustomerSupportService>().getIssuesAndAnnouncement());
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          event.complete(null);
          return;
        }

      case NotificationType.galleryNewNft:
      case NotificationType.newPostcardTrip:
      case NotificationType.jgCrystallineWorkGenerated:
      case NotificationType.jgCrystallineWorkHasArrived:
        unawaited(_clientTokenService.refreshTokens());
      case NotificationType.artworkCreated:
      case NotificationType.artworkReceived:
      default:
        break;
    }

    // show notification
    switch (notificationType) {
      case NotificationType.customerSupportNewAnnouncement:
        showInfoNotification(
            const Key('Announcement'), 'au_has_announcement'.tr(),
            addOnTextSpan: [
              TextSpan(
                  text: 'tap_to_view'.tr(),
                  style: Theme.of(context).textTheme.ppMori400FFYellow14),
            ], openHandler: () async {
          final announcementID = '${data["id"]}';
          unawaited(_openAnnouncement(context, announcementID));
        });
      case NotificationType.newMessage:
        final groupId = data['group_id'];

        if (!_remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
          return;
        }

        final currentGroupId = memoryValues.currentGroupChatId;
        if (groupId != currentGroupId) {
          showNotifications(context, event.notification,
              notificationOpenedHandler: (notification) async {
            await handleNotificationClicked(
                context, notification, pageController);
          });
        }
      default:
        showNotifications(context, event.notification,
            notificationOpenedHandler: (notification) async {
          await handleNotificationClicked(
              context, notification, pageController);
        });
    }
    event.complete(null);
  }

  Future<void> _openAnnouncement(
      BuildContext context, String announcementID) async {
    log.info('Open announcement: id = $announcementID');
    await injector<CustomerSupportService>().fetchAnnouncement();
    final announcement = await injector<CustomerSupportService>()
        .findAnnouncement(announcementID);
    if (announcement != null) {
      if (!context.mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.supportThreadPage,
        (route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition,
        arguments: NewIssuePayload(
          reportIssueType: ReportIssueType.Announcement,
          announcement: announcement,
        ),
      ));
    }
  }
}
