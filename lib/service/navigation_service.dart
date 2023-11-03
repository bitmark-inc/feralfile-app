//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/claim/activation/claim_activation_page.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/share_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart'; // ignore: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const Key contactingKey = Key("tezos_beacon_contacting");

  // to prevent showing duplicate ConnectPage
  // workaround solution for unknown reason ModalRoute(navigatorKey.currentContext) returns nil
  bool _isWCConnectInShow = false;

  BuildContext get context => navigatorKey.currentContext!;

  bool get mounted => navigatorKey.currentContext?.mounted == true;

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info("NavigationService.navigateTo: $routeName");

    if (routeName == AppRouter.wcConnectPage && _isWCConnectInShow) {
      log.info("[NavigationService] skip because WCConnectPage is in showing");
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
    log.info("NavigationService.popAndPushNamed: $routeName");

    if (routeName == AppRouter.wcConnectPage && _isWCConnectInShow) {
      log.info(
          "[NavigationService] skip popAndPushNamed because WCConnectPage is in showing");
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }

  Future<dynamic>? navigateUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    log.info("NavigationService.navigateTo: $routeName");

    if (routeName == AppRouter.wcConnectPage && _isWCConnectInShow) {
      log.info("[NavigationService] skip because WCConnectPage is in showing");
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(routeName, predicate);
  }

  NavigatorState navigatorState() {
    return Navigator.of(navigatorKey.currentContext!);
  }

  Future showAirdropNotStarted(String? artworkId) async {
    log.info("NavigationService.showAirdropNotStarted");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showAirdropNotStarted(
          navigatorKey.currentContext!, artworkId);
    } else {
      Future.value(0);
    }
  }

  Future showAirdropExpired(String? artworkId) async {
    log.info("NavigationService.showAirdropExpired");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showAirdropExpired(
          navigatorKey.currentContext!, artworkId);
    } else {
      Future.value(0);
    }
  }

  Future showNoRemainingToken({
    required FFSeries series,
  }) async {
    log.info("NavigationService.showNoRemainingToken");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showNoRemainingAirdropToken(
        navigatorKey.currentContext!,
        series: series,
      );
    } else {
      Future.value(0);
    }
  }

  Future showOtpExpired(String? artworkId) async {
    log.info("NavigationService.showOtpExpired");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showOtpExpired(navigatorKey.currentContext!, artworkId);
    } else {
      Future.value(0);
    }
  }

  Future openClaimTokenPage(
    FFSeries series, {
    Otp? otp,
  }) async {
    log.info("NavigationService.openClaimTokenPage");
    final isAllowViewOnlyClaim = AirdropType.Memento6.seriesId == series.id;
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.claimFeralfileTokenPage,
        arguments: ClaimTokenPageArgs(
          series: series,
          otp: otp,
          allowViewOnlyClaim: isAllowViewOnlyClaim,
        ),
      );
    } else {
      Future.value(0);
    }
  }

  Future<void> openActivationPage(
      {required ClaimActivationPagePayload payload}) async {
    log.info("NavigationService.openActivationPage");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.claimActivationPage,
        arguments: payload,
      );
    } else {
      Future.value(0);
    }
  }

  void showErrorDialog(
    ErrorEvent event, {
    Function()? defaultAction,
    Function()? cancelAction,
  }) {
    log.info("NavigationService.showErrorDialog");

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
    log.info("NavigationService.goBack");
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

  void showContactingDialog() async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      final metricClient = injector.get<MetricClientService>();
      metricClient.timerEvent(MixpanelEvent.cancelContact);

      bool dialogShowed = false;
      showInfoNotificationWithLink(
        contactingKey,
        "establishing_contact".tr(),
        frontWidget: loadingIndicator(valueColor: AppColor.white),
        bottomRightWidget: GestureDetector(
          onTap: () {
            dialogShowed = true;
            waitTooLongDialog();
          },
          child: Text(
            "taking_too_long".tr(),
            style: Theme.of(navigatorKey.currentContext!)
                .textTheme
                .ppMori400White12
                .copyWith(
                    color: AppColor.auQuickSilver,
                    decoration: TextDecoration.underline),
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
      metricClient.addEvent(MixpanelEvent.connectContactSuccess);
    }
  }

  Future<void> waitTooLongDialog() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
        navigatorKey.currentContext!,
        "taking_too_long".tr(),
        'if_take_too_long'.tr(),
        closeButton: "cancel".tr(),
        isDismissible: true,
        autoDismissAfter: 20,
        onClose: () {
          injector
              .get<MetricClientService>()
              .addEvent(MixpanelEvent.cancelContact);
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
      Future.value(0);
    }
  }

  Future<void> showAlreadyDeliveredPostcard() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAlreadyDelivered(navigatorKey.currentContext!);
    }
  }

  Future<void> showAirdropJustOnce() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAirdropJustOnce(navigatorKey.currentContext!);
    }
  }

  Future<void> showAirdropAlreadyClaimed() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAirdropAlreadyClaim(navigatorKey.currentContext!);
    }
  }

  Future<void> showAirdropClaimFailed() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAirdropClaimFailed(navigatorKey.currentContext!);
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

  Future<void> openAutonomyDocument(String href, String title) async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      final uri = Uri.parse(href.autonomyRawDocumentLink);
      final document = uri.pathSegments.last;
      final prefix =
          uri.pathSegments.sublist(0, uri.pathSegments.length - 1).join("/");
      await Navigator.of(navigatorKey.currentContext!)
          .pushNamed(AppRouter.githubDocPage, arguments: {
        "prefix": "/$prefix/",
        "document": document,
        "title": title,
      });
    }
  }

  Future<void> showOptionsAfterSharePostcard(
      {required AssetToken assetToken, Function()? callBack}) async {
    final theme = Theme.of(context);
    final postcardService = injector.get<PostcardService>();
    bool isProcessing = false;
    final isStamped = assetToken.isStamped;
    final options = [
      OptionItem(
        title: "stamp_minted".tr(),
        titleStyle: theme.textTheme.moMASans700Black16
            .copyWith(color: MoMAColors.moMA1, fontSize: 18),
        icon: SvgPicture.asset("assets/images/moma_arrow_right.svg"),
        onTap: () async {
          Navigator.of(context).pop();
          await callBack?.call();
        },
        separator: const Divider(
          height: 1,
          thickness: 1.0,
          color: Color.fromRGBO(203, 203, 203, 1),
        ),
      ),
      OptionItem(
        title: 'share_on_'.tr(),
        icon: SvgPicture.asset(
          'assets/images/globe.svg',
          width: 24,
          height: 24,
        ),
        iconOnProcessing: SvgPicture.asset(
          'assets/images/globe.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColor.disabledColor,
            BlendMode.srcIn,
          ),
        ),
        onTap: () async {
          isProcessing = true;
          shareToTwitter(token: assetToken);
          Navigator.of(context).pop();
          await callBack?.call();
        },
      ),
      OptionItem(
        title: 'download_stamp'.tr(),
        isEnable: isStamped,
        icon: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
        ),
        iconOnProcessing: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColor.disabledColor,
            BlendMode.srcIn,
          ),
        ),
        iconOnDisable: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColor.disabledColor,
            BlendMode.srcIn,
          ),
        ),
        onTap: () async {
          isProcessing = true;
          try {
            await postcardService.downloadStamp(
                tokenId: assetToken.tokenId!,
                stampIndex: assetToken.stampIndexWithStamping);
            if (!mounted) return;
            Navigator.of(context).pop();
            await UIHelper.showPostcardStampSaved(context);
            await callBack?.call();
          } catch (e) {
            log.info("Download stamp failed: error ${e.toString()}");
            if (!mounted) return;
            Navigator.of(context).pop();

            switch (e.runtimeType) {
              case MediaPermissionException:
                await UIHelper.showPostcardStampPhotoAccessFailed(context);
                break;
              default:
                if (!mounted) return;
                await UIHelper.showPostcardStampSavedFailed(context);
            }
            await callBack?.call();
          }
        },
      ),
      OptionItem(
        title: 'download_postcard'.tr(),
        isEnable: isStamped,
        icon: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
        ),
        iconOnProcessing: SvgPicture.asset('assets/images/download.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
                AppColor.disabledColor, BlendMode.srcIn)),
        iconOnDisable: SvgPicture.asset('assets/images/download.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
                AppColor.disabledColor, BlendMode.srcIn)),
        onTap: () async {
          isProcessing = true;
          try {
            await postcardService.downloadPostcard(assetToken.tokenId!);
            if (!mounted) return;
            Navigator.of(context).pop();
            await UIHelper.showPostcardSaved(context);
          } catch (e) {
            log.info("Download postcard failed: error ${e.toString()}");
            if (!mounted) return;
            Navigator.of(context).pop();
            switch (e.runtimeType) {
              case MediaPermissionException:
                await UIHelper.showPostcardPhotoAccessFailed(context);
                break;
              default:
                if (!mounted) return;
                await UIHelper.showPostcardSavedFailed(context);
            }
          }
        },
      ),
    ];
    await UIHelper.showPostcardDrawerAction(context, options: options)
        .then((value) {
      if (!isProcessing) callBack?.call();
    });
  }
}
