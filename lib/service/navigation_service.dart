import 'dart:async';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/biometric_lock/lock_page.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();
  bool _isAppLocking = false;

  // to prevent showing duplicate ConnectPage
  // workaround solution for unknown reason ModalRoute(navigatorKey.currentContext) returns nil
  bool _isWCConnectInShow = false;
  Completer<void>? _finishLocking;

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info("NavigationService.navigateTo: $routeName");

    if (routeName == AppRouter.wcConnectPage && _isWCConnectInShow) {
      log.info("[NavigationService] skip because WCConnectPage is in showing");
      return null;
    }

    final f =
        navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);

    return _finishLocking != null ? _finishLocking!.future.then((_) => f) : f;
  }

  Future<dynamic>? lockScreen() async {
    if (_isAppLocking) return;
    _isAppLocking = true;
    await navigatorKey.currentState?.push(LockingOverlay());
    _finishLocking = Completer();
    return _finishLocking;
  }

  void unlockScreen() {
    _isAppLocking = false;
    navigatorKey.currentState?.pop();
    _finishLocking?.complete();
  }

  void goBack() {
    log.info("NavigationService.goBack");
    return navigatorKey.currentState?.pop();
  }

  void setIsWCConnectInShow(bool appeared) {
    _isWCConnectInShow = appeared;
  }
}
