import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  final _metricClient = injector<MetricClientService>();
  static Route<dynamic>? currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      unawaited(
        _metricClient.trackEndScreen(previousRoute).then(
          (value) {
            _metricClient.trackStartScreen(route: route);
          },
        ),
      );
    }
    currentRoute = route;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(
      _metricClient.trackEndScreen(route).then(
        (value) {
          if (previousRoute != null) {
            _metricClient.trackStartScreen(route: previousRoute);
          }
        },
      ),
    );
    currentRoute = previousRoute;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      unawaited(_metricClient.trackEndScreen(oldRoute));
    }
    if (newRoute != null) {
      unawaited(_metricClient.trackStartScreen(route: newRoute));
    }
    currentRoute = newRoute;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
