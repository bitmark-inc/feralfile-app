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

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info("NavigationService.navigateTo: $routeName");

    if (routeName == AppRouter.wcConnectPage && _isWCConnectInShow) {
      log.info("[NavigationService] skip because WCConnectPage is in showing");
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic>? lockScreen() async {
    if (_isAppLocking) return;
    _isAppLocking = true;
    return navigatorKey.currentState?.push(LockingOverlay());
  }

  Future<dynamic>? unlockScreen() async {
    _isAppLocking = false;
    return navigatorKey.currentState?.pop();
  }

  void goBack() {
    log.info("NavigationService.goBack");
    return navigatorKey.currentState?.pop();
  }

  void setIsWCConnectInShow(bool appeared) {
    _isWCConnectInShow = appeared;
  }
}
