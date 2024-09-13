// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class MetricClientService {
  MetricClientService();

  bool isFinishInit = false;

  Future<void> initService() async {
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
    // ignore: unused_local_variable
    final dataWithExtend = {
      ...data,
      'platform': 'Feral File App',
    };
    // add event here
  }

  void timerEvent(String name) {
    if (isFinishInit) {
      // time event here
    }
  }

  Future<void> mergeUser(String oldUserId) async {
    if (isFinishInit) {
      // new userId will include in jwt token
      await injector<IAPApi>().updateMetrics(oldUserId);
    }
  }

  void setLabel(String prop, dynamic value) {
    if (isFinishInit) {
      // mixPanelClient.setLabel(prop, value);
    }
  }

  void incrementPropertyLabel(String prop, double value) {
    if (isFinishInit) {
      // mixPanelClient.incrementPropertyLabel(prop, value);
    }
  }

  void reset() {
    if (isFinishInit) {
      // mixPanelClient.reset();
    }
  }
}
