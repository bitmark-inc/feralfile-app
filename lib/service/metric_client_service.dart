// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:sentry/sentry.dart';

class MetricClientService {
  MetricClientService();

  String _identifier = '';

  String _defaultIdentifier() => injector<DeviceInfoService>().deviceId;

  Future<void> initService({String? identifier}) async {
    _identifier = identifier ?? _defaultIdentifier();
  }

  Future<void> identity() async {
    log.info('Metric identity: $_identifier');
    try {
      final primaryAddress =
          await injector<AddressService>().getPrimaryAddress();
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
      log.info('Metric identity updated: $_identifier');
    } catch (e) {
      log.info('Metric identity error: $e');
      unawaited(Sentry.captureException('Metric identity error: $e'));
    }
  }

  Future<void> addEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    log.info('Metric add event: $name');
    final configurationService = injector.get<ConfigurationService>();

    if (!configurationService.isAnalyticsEnabled()) {
      log.info('Metric add event: Analytics is disabled');
      return;
    }
    // ignore: unused_local_variable
    final dataWithExtend = {
      'event': name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'parameters': {
        ...data,
        'platform': platform,
      }
    };

    final metrics = {
      'metrics': [
        dataWithExtend,
      ]
    };
    try {
      await injector<IAPApi>().sendEvent(metrics, _identifier);
      log.info('Metric add event done: $name');
    } catch (e, s) {
      log.info('Metric add event error: $e');
      unawaited(
          Sentry.captureException('Metric add event error: $e', stackTrace: s));
    }
  }

  void timerEvent(String name) {
    // time event here
  }

  Future<void> mergeUser(String oldUserId) async {
    // new userId will include in jwt token
    log.info('Metric merge user: $oldUserId');
    try {
      await injector<IAPApi>().updateMetrics(oldUserId);
      log.info('Metric merge user done: $oldUserId');
    } catch (e) {
      log.info('Metric merge user error: $e');
      unawaited(Sentry.captureException('Metric merge user error: $e'));
    }
  }

  void setLabel(String prop, dynamic value) {
    // mixPanelClient.setLabel(prop, value);
  }

  void incrementPropertyLabel(String prop, double value) {
    // mixPanelClient.incrementPropertyLabel(prop, value);
  }

  Future<void> reset() async {
    log.info('Metric reset');
    try {
      final deviceId = _defaultIdentifier();
      await injector<IAPApi>().deleteMetrics(deviceId);
      _identifier = deviceId;
      log.info('Metric reset done');
    } catch (e) {
      log.info('Metric reset error: $e');
      unawaited(Sentry.captureException('Metric reset error: $e'));
    }
  }
}
