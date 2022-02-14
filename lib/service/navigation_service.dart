import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info("NavigationService.navigateTo: $routeName");
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  void goBack() {
    log.info("NavigationService.goBack");
    return navigatorKey.currentState?.pop();
  }
}
