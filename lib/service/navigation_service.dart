//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/feral_file_helper.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:nft_collection/models/asset_token.dart'; // ignore_for_file: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const Key contactingKey = Key('tezos_beacon_contacting');

  // to prevent showing duplicate ConnectPage
  // workaround solution for unknown reason
  // ModalRoute(navigatorKey.currentContext) returns nil
  bool _isWCConnectInShow = false;

  BuildContext get context => navigatorKey.currentContext!;

  bool get mounted => navigatorKey.currentContext?.mounted == true;

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info('NavigationService.navigateTo: $routeName');

    if ((routeName == AppRouter.tbConnectPage ||
            routeName == AppRouter.wc2ConnectPage) &&
        _isWCConnectInShow) {
      log.info('[NavigationService] skip because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic>? popAndPushNamed(String routeName, {Object? arguments}) {
    log.info('NavigationService.popAndPushNamed: $routeName');

    if ((routeName == AppRouter.wc2ConnectPage ||
            routeName == AppRouter.tbConnectPage) &&
        _isWCConnectInShow) {
      log.info(
          // ignore: lines_longer_than_80_chars
          '[NavigationService] skip popAndPushNamed because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }

  Future<void> selectPromptsThenStamp(
      BuildContext context, AssetToken asset, String? shareCode) async {
    final prompt = asset.postcardMetadata.prompt;

    await popAndPushNamed(
        prompt == null ? AppRouter.promptPage : AppRouter.designStamp,
        arguments: DesignStampPayload(asset, true, shareCode));
  }

  Future<dynamic>? navigateUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    log.info('NavigationService.navigateTo: $routeName');

    if ((routeName == AppRouter.tbConnectPage ||
            routeName == AppRouter.wc2ConnectPage) &&
        _isWCConnectInShow) {
      log.info('[NavigationService] skip because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(routeName, predicate);
  }

  NavigatorState navigatorState() => Navigator.of(navigatorKey.currentContext!);

  void showErrorDialog(
    ErrorEvent event, {
    Function()? defaultAction,
    Function()? cancelAction,
  }) {
    log.info('NavigationService.showErrorDialog');

    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      showErrorDiablog(
        navigatorKey.currentContext!,
        event,
        defaultAction: defaultAction,
        cancelAction: cancelAction,
      );
    }
  }

  void hideInfoDialog() {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      UIHelper.hideInfoDialog(navigatorKey.currentContext!);
    }
  }

  void goBack({Object? result}) {
    log.info('NavigationService.goBack');
    return navigatorKey.currentState?.pop(result);
  }

  void popUntilHome() {
    navigatorKey.currentState?.popUntil((route) =>
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition);
  }

  void popUntilHomeOrSettings() {
    navigatorKey.currentState?.popUntil((route) =>
        route.settings.name == AppRouter.settingsPage ||
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition);
  }

  void restorablePushHomePage() {
    navigatorKey.currentState?.restorablePushNamedAndRemoveUntil(
        AppRouter.homePageNoTransition,
        (route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
  }

  void setIsWCConnectInShow(bool appeared) {
    _isWCConnectInShow = appeared;
  }

  Future<void> showContactingDialog() async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      bool dialogShowed = false;
      showInfoNotificationWithLink(
        contactingKey,
        'establishing_contact'.tr(),
        frontWidget: loadingIndicator(valueColor: AppColor.white),
        bottomRightWidget: GestureDetector(
          onTap: () {
            dialogShowed = true;
            waitTooLongDialog();
          },
          child: Text(
            'taking_too_long'.tr(),
            style: Theme.of(navigatorKey.currentContext!)
                .textTheme
                .ppMori400White12
                .copyWith(
                  color: AppColor.auQuickSilver,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColor.auQuickSilver,
                ),
          ),
        ),
        duration: const Duration(seconds: 15),
      );
      final OverlaySupportState? overlaySupport = findOverlayState();
      Future.delayed(const Duration(seconds: 4), () {
        if (!dialogShowed &&
            overlaySupport != null &&
            overlaySupport.getEntry(key: contactingKey) != null) {
          dialogShowed = true;
          waitTooLongDialog();
        }
      });
    }
  }

  Future<void> waitTooLongDialog() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
        navigatorKey.currentContext!,
        'taking_too_long'.tr(),
        'if_take_too_long'.tr(),
        closeButton: 'cancel'.tr(),
        isDismissible: true,
        autoDismissAfter: 20,
        onClose: () {
          hideInfoDialog();
        },
      );
    }
  }

  Future<void> showDeclinedGeolocalization() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showDeclinedGeolocalization(navigatorKey.currentContext!);
    }
  }

  Future<void> openPostcardReceivedPage(
      {required AssetToken asset, required String shareCode}) async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.receivePostcardPage,
        arguments: ReceivePostcardPageArgs(asset: asset, shareCode: shareCode),
      );
    } else {
      await Future.value(0);
    }
  }

  Future<void> gotoExhibitionDetailsPage(String exhibitionID) async {
    popUntilHome();
    await Future.delayed(const Duration(seconds: 1), () async {
      await (homePageKey.currentState ?? homePageNoTransactionKey.currentState)
          ?.openExhibition(exhibitionID ?? '');
    });
  }

  Future<void> gotoArtworkDetailsPage(String indexID) async {
    popUntilHome();
    final tokens = await injector<NftCollectionDatabase>()
        .assetTokenDao
        .findAllAssetTokensByTokenIDs([indexID]);
    final owner = tokens.first.owner;
    final artworkDetailPayload =
        ArtworkDetailPayload([ArtworkIdentity(indexID, owner)], 0);
    if (context.mounted) {
      unawaited(Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
          arguments: artworkDetailPayload));
    }
  }

  Future<dynamic> goToIRLWebview(IRLWebScreenPayload payload) async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      return await navigateTo(AppRouter.irlWebView, arguments: payload);
    } else {
      return {'result': false};
    }
  }

  Future<void> showAlreadyDeliveredPostcard() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAlreadyDelivered(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardShareLinkExpired() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardShareLinkExpired(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardShareLinkInvalid() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardShareLinkInvalid(navigatorKey.currentContext!);
    }
  }

  Future<void> showLocationExplain() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showLocationExplain(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardRunOut() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardRunOut(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardQRCodeExpired() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardQRExpired(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardClaimLimited() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardClaimLimited(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardNotInMiami() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardNotInMiami(navigatorKey.currentContext!);
    }
  }

  Future<void> openAutonomyDocument(String href, String title) async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      final uri = Uri.parse(href.autonomyRawDocumentLink);
      final document = uri.pathSegments.last;
      final prefix =
          uri.pathSegments.sublist(0, uri.pathSegments.length - 1).join('/');
      await Navigator.of(navigatorKey.currentContext!)
          .pushNamed(AppRouter.githubDocPage, arguments: {
        'prefix': '/$prefix/',
        'document': document,
        'title': title,
      });
    }
  }

  Future<void> openFeralFileArtistPage(String alias) async {
    if (alias.contains(',') || alias.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getArtistUrl(alias);
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
        AppRouter.inappWebviewPage,
        arguments: InAppWebViewPayload(url));
  }

  Future<void> openFeralFileCuratorPage(String alias) async {
    if (alias.contains(',') || alias.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getCuratorUrl(alias);
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
        AppRouter.inappWebviewPage,
        arguments: InAppWebViewPayload(url));
  }

  Future<void> openFeralFileExhibitionNotePage(String exhibitionSlug) async {
    if (exhibitionSlug.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getExhibitionNoteUrl(exhibitionSlug);
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppRouter.inappWebviewPage,
      arguments: InAppWebViewPayload(url),
    );
  }

  Future<void> openFeralFilePostPage(Post post, String exhibitionID) async {
    if (post.slug.isEmpty || exhibitionID.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getPostUrl(post, exhibitionID);
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppRouter.inappWebviewPage,
      arguments: InAppWebViewPayload(url),
    );
  }
}
