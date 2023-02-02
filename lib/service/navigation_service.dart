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
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  Future showAirdropNotStarted() async {
    log.info("NavigationService.showAirdropNotStarted");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showAirdropNotStarted(
        navigatorKey.currentContext!,
      );
    } else {
      Future.value(0);
    }
  }

  Future showAirdropExpired() async {
    log.info("NavigationService.showAirdropExpired");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showAirdropExpired(navigatorKey.currentContext!);
    } else {
      Future.value(0);
    }
  }

  Future showNoRemainingToken({
    required FFArtwork artwork,
  }) async {
    log.info("NavigationService.showNoRemainingToken");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showNoRemainingAirdropToken(
        navigatorKey.currentContext!,
        artwork: artwork,
      );
    } else {
      Future.value(0);
    }
  }

  Future showOtpExpired() async {
    log.info("NavigationService.showOtpExpired");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await UIHelper.showOtpExpired(navigatorKey.currentContext!);
    } else {
      Future.value(0);
    }
  }

  Future openClaimTokenPage(
    FFArtwork artwork, {
    Otp? otp,
  }) async {
    log.info("NavigationService.openClaimTokenPage");
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.claimFeralfileTokenPage,
        arguments: ClaimTokenPageArgs(
          artwork: artwork,
          otp: otp,
        ),
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

  void goBack() {
    log.info("NavigationService.goBack");
    return navigatorKey.currentState?.pop();
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
      await UIHelper.showInfoDialog(
        navigatorKey.currentContext!,
        'contacting'.tr(),
        'contact_with_dapp'.tr(),
        closeButton: "cancel_dialog".tr(),
        isDismissible: true,
        autoDismissAfter: 20,
        onClose: () {
          metricClient.addEvent(MixpanelEvent.cancelContact);
          hideInfoDialog();
        },
      );
      metricClient.addEvent(MixpanelEvent.connectContactSuccess);
    }
  }
}
