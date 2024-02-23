// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:developer';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/foundation.dart';

class MetricClientService {
  MetricClientService();

  final mixPanelClient = injector<MixPanelClientService>();
  bool isFinishInit = false;

  Future<void> initService() async {
    await mixPanelClient.initService();
    isFinishInit = true;
  }

  Future<void> _addEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    final configurationService = injector.get<ConfigurationService>();

    if (!configurationService.isAnalyticsEnabled()) {
      return;
    }
    if (isFinishInit) {
      unawaited(mixPanelClient.trackEvent(
        name,
        message: message,
        data: data,
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
      log(e.toString());
    }
  }

  Future<void> trackStartScreen(String? screen) async {
    if (screen == null) {
      return;
    }
  }

  Future<void> trackEndScreen(String? screen) async {
    if (screen == null) {
      return;
    }
  }

  void setLabel(String prop, dynamic value) {
    if (isFinishInit) {
      mixPanelClient.setLabel(prop, value);
    }
  }

  void _incrementPropertyLabel(String prop, double value) {
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
}
