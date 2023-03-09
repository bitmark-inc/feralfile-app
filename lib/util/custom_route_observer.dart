import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:flutter/material.dart';

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  final _metricClient = injector<MetricClientService>();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _metricClient.trackEndScreen(previousRoute.settings.name);
    }
    _metricClient.trackStartScreen(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _metricClient.trackEndScreen(route.settings.name);
    if (previousRoute != null) {
      _metricClient.trackStartScreen(previousRoute.settings.name);
    }
    super.didPop(route, previousRoute);
  }
}
