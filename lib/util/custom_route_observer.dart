import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:flutter/cupertino.dart';

const dialogRouteType = [];

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  final _metricClient = injector<MetricClientService>();
  Route<dynamic>? _previousRoute;
  Route<dynamic>? _currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!dialogRouteType.contains(previousRoute.runtimeType)) {
      _previousRoute = previousRoute;
    }
    _currentRoute = route;
    if (dialogRouteType.contains(_previousRoute.runtimeType)) {
      return;
    }
    if (_previousRoute != null) {
      unawaited(
        _metricClient.trackEndScreen(_previousRoute!).then(
          (value) {
            if (_currentRoute != null)
              _metricClient.trackStartScreen(_currentRoute!);
          },
        ),
      );
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!dialogRouteType.contains(route.runtimeType)) {
      _currentRoute = route;
    }
    _previousRoute = previousRoute;
    if (_currentRoute != null) {
      unawaited(
        _metricClient.trackEndScreen(_currentRoute!).then(
          (value) {
            if (_previousRoute != null) {
              _metricClient.trackStartScreen(_previousRoute!);
            }
          },
        ),
      );
    }

    super.didPop(route, previousRoute);
  }
}
