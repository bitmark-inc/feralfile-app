// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/route_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MetricClientService {
  MetricClientService();

  final mixPanelClient = injector<MixPanelClientService>();
  bool isFinishInit = false;
  Timer? _timer;

  Future<void> initService() async {
    await mixPanelClient.initService();
    isFinishInit = true;
  }

  void addEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) {
    final configurationService = injector.get<ConfigurationService>();

    if (!configurationService.isAnalyticsEnabled()) {
      return;
    }
    final dataWithExtend = {
      ...data,
      'platform': 'Feral File App',
    };
    if (isFinishInit) {
      unawaited(mixPanelClient.trackEvent(
        name,
        message: message,
        data: dataWithExtend,
        hashedData: hashedData,
      ));
      unawaited(mixPanelClient.sendData());
    }
  }

  void timerEvent(String name) {
    if (isFinishInit) {
      mixPanelClient.timerEvent(name.snakeToCapital());
    }
  }

  Future<void> sendAndClearMetrics() async {
    try {
      if (!kDebugMode) {
        await mixPanelClient.sendData();
      }
    } catch (e) {
      log.info(e.toString());
    }
  }

  Future<void> trackStartScreen({Route<dynamic>? route}) async {
    timerEvent(MixpanelEvent.visitPage);
  }

  Future<void> trackEndScreen(Route<dynamic> route) async {
    if (route.isIgnoreForVisitPageEvent) {
      return;
    }
    final screenName = route.metricTitle;
    Map<String, dynamic> data = route.metricData..addAll({'title': screenName});
    addEvent(MixpanelEvent.visitPage, data: data);
  }

  void setLabel(String prop, dynamic value) {
    if (isFinishInit) {
      mixPanelClient.setLabel(prop, value);
    }
  }

  void incrementPropertyLabel(String prop, double value) {
    if (isFinishInit) {
      mixPanelClient.incrementPropertyLabel(prop, value);
    }
  }

  Future<void> initConfigIfNeed(Map<String, dynamic> config) async {
    await mixPanelClient.initConfigIfNeed(config);
  }

  dynamic getConfig(String key, {dynamic defaultValue}) =>
      mixPanelClient.getConfig(key, defaultValue: defaultValue);

  Future<void> setConfig(String key, dynamic value) async {
    await mixPanelClient.setConfig(key, value);
  }

  void onBackground() {
    _timer?.cancel();
    const duration = Duration(seconds: 60);
    _timer = Timer(duration, () {
      final route = CustomRouteObserver.currentRoute;
      if (route?.settings.name == AppRouter.homePage) {
        homePageKey.currentState?.sendVisitPageEvent();
      } else if (route?.settings.name == AppRouter.homePageNoTransition) {
        homePageNoTransactionKey.currentState?.sendVisitPageEvent();
      } else if (route != null) {
        unawaited(trackEndScreen(route));
      }
    });
  }

  void onForeground() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    } else {
      final route = CustomRouteObserver.currentRoute;
      if (route != null) {
        unawaited(trackStartScreen(route: route));
      }
    }
  }
}
