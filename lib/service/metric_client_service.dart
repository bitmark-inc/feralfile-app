// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:sentry/sentry.dart';

class MetricClientService {
  MetricClientService();

  bool isFinishInit = false;

  String _identifier = '';

  String _defaultIdentifier() => injector<DeviceInfoService>().deviceId;

  Future<void> initService({String? identifier}) async {
    _identifier = identifier ?? _defaultIdentifier();
    isFinishInit = true;

    // count open app
    await addEvent(MetricEventName.openApp.name);
  }

  Future<void> identity() async {
    final primaryAddress = await injector<AddressService>().getPrimaryAddress();
    if (primaryAddress == null) {
      unawaited(
          Sentry.captureMessage('Metric Identity: Primary address is null'));
      return;
    }
    if (primaryAddress == _identifier) {
      return;
    }
    await mergeUser(_identifier);
    _identifier = primaryAddress;
  }

  Future<void> addEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    final configurationService = injector.get<ConfigurationService>();

    if (!configurationService.isAnalyticsEnabled()) {
      return;
    }
    // ignore: unused_local_variable
    final dataWithExtend = {
      'event': name,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': {
        ...data,
        'platform': platform,
      }
    };
    await injector<IAPApi>().sendEvent(dataWithExtend, _identifier);
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
