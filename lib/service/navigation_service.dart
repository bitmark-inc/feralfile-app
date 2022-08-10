//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
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

    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  void showFFAccountLinked(String alias, {bool inOnboarding = false}) {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      UIHelper.showFFAccountLinked(navigatorKey.currentContext!, alias,
          inOnboarding: inOnboarding);
    }
  }

  void showErrorDialog(
    ErrorEvent event, {
    Function()? defaultAction,
    Function()? cancelAction,
  }) {
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

  void setIsWCConnectInShow(bool appeared) {
    _isWCConnectInShow = appeared;
  }
}
