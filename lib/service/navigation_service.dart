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
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';
// ignore: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const Key contactingKey = Key("tezos_beacon_contacting");

  // to prevent showing duplicate ConnectPage
  // workaround solution for unknown reason ModalRoute(navigatorKey.currentContext) returns nil
  bool _isWCConnectInShow = false;

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

  void showFFAccountLinked(String alias, {bool inOnboarding = false}) {
    log.info("NavigationService.showFFAccountLinked: $alias");

    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      UIHelper.showFFAccountLinked(navigatorKey.currentContext!, alias,
          inOnboarding: inOnboarding);
    }
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
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.claimFeralfileTokenPage,
        arguments: ClaimTokenPageArgs(
          series: series,
          otp: otp,
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
}
