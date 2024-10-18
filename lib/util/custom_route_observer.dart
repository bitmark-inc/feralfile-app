import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  static Route<dynamic>? currentRoute;

  static bool _onIgnoreBackLayerPopUp = false;

  static bool get onIgnoreBackLayerPopUp => _onIgnoreBackLayerPopUp;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    /// this must be put before super.didPush
    if (route.settings.name == UIHelper.ignoreBackLayerPopUpRouteName) {
      _onIgnoreBackLayerPopUp = true;
    }

    currentRoute = route;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = previousRoute;
    super.didPop(route, previousRoute);

    /// this must be put after super.didPop
    if (route.settings.name == UIHelper.ignoreBackLayerPopUpRouteName) {
      _onIgnoreBackLayerPopUp = false;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRoute = newRoute;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
