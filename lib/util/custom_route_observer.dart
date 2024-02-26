import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:flutter/material.dart';

class CustomRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  final _metricClient = injector<MetricClientService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(_metricClient.trackStartScreen(route));
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      unawaited(_metricClient.trackStartScreen(previousRoute));
    }
    super.didPop(route, previousRoute);
  }
}
