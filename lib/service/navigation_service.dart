import 'package:autonomy_flutter/screen/biometric_lock/lock_page.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();
  bool _isAppLocking = false;

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info("NavigationService.navigateTo: $routeName");
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
}
