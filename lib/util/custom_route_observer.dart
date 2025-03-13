import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final listRouteShouldnotShowNowDisplaying = [
  AppRouter.scanQRPage,
  AppRouter.settingsPage,
  AppRouter.subscriptionPage,
  AppRouter.supportCustomerPage,
  AppRouter.supportListPage,
  AppRouter.supportThreadPage,
  AppRouter.walletPage,
  AppRouter.linkedWalletDetailsPage,
  AppRouter.preferencesPage,
  AppRouter.hiddenArtworksPage,
  AppRouter.dataManagementPage,
  AppRouter.bugBountyPage,
  AppRouter.nowDisplayingPage,
  AppRouter.onboardingPage,
  AppRouter.newOnboardingPage,
  AppRouter.bluetoothConnectedDeviceConfig,
  AppRouter.bluetoothDevicePortalPage,
  AppRouter.onboardingPage,
];

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  static Route<dynamic>? currentRoute;

  static bool _onIgnoreBackLayerPopUp = false;

  static bool get onIgnoreBackLayerPopUp => _onIgnoreBackLayerPopUp;

  Timer? _timer;

  void onCurrentRouteChanged() {
    if (currentRoute != null) {
      final routeName = currentRoute!.settings.name;
      if (routeName == null ||
          routeName == UIHelper.ignoreBackLayerPopUpRouteName) {
        return;
      }
      if (listRouteShouldnotShowNowDisplaying.contains(routeName)) {
        _timer?.cancel();
        _timer = Timer.periodic(Duration(milliseconds: 50), (_) {
          _timer?.cancel();
          shouldShowNowDisplaying.value = false;
        });
      } else {
        log.info('shouldShowNowDisplaying.value = true');
        _timer?.cancel();
        _timer = Timer.periodic(Duration(milliseconds: 50), (_) {
          _timer?.cancel();
          shouldShowNowDisplaying.value = true;
        });
        // shouldShowNowDisplaying.value = true;
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    /// this must be put before super.didPush
    if (route.settings.name == UIHelper.ignoreBackLayerPopUpRouteName) {
      _onIgnoreBackLayerPopUp = true;
    }
    super.didPush(route, previousRoute);

    currentRoute = route;
    onCurrentRouteChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute = previousRoute;
    onCurrentRouteChanged();

    /// this must be put after super.didPop
    if (route.settings.name == UIHelper.ignoreBackLayerPopUpRouteName) {
      _onIgnoreBackLayerPopUp = false;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute = newRoute;
    onCurrentRouteChanged();
  }
}
