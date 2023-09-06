import 'dart:async';
import 'dart:developer';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/foundation.dart';

class MetricClientService {
  final AccountService _accountService;
  late Timer? useAppTimer;

  MetricClientService(this._accountService);

  final mixPanelClient = injector<MixPanelClientService>();
  bool isFinishInit = false;

  Future<void> initService() async {
    await mixPanelClient.initService();
    isFinishInit = true;
    await onOpenApp();
    useAppTimer = Timer(USE_APP_MIN_DURATION, () async {
      await onUseAppInForeground();
    });
  }

  Future<void> addEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    final configurationService = injector.get<ConfigurationService>();

    if (configurationService.isAnalyticsEnabled() == false) {
      return;
    }
    if (isFinishInit) {
      mixPanelClient.trackEvent(
        name,
        message: message,
        data: data,
        hashedData: hashedData,
      );
      mixPanelClient.mixpanel.flush();
    }
  }

  timerEvent(String name) {
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
    await addEvent(MixpanelEvent.viewScreen,
        data: {"screen": screen.snakeToCapital()});
    await timerEvent(MixpanelEvent.endViewScreen);
  }

  Future<void> trackEndScreen(String? screen) async {
    if (screen == null) {
      return;
    }
    await addEvent(MixpanelEvent.endViewScreen,
        data: {"screen": screen.snakeToCapital()});
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

  void onAddConnection(Connection connection) {
    if (isFinishInit) {
      mixPanelClient.onAddConnection(connection);
    }
  }

  void onRemoveConnection(Connection connection) {
    if (isFinishInit) {
      mixPanelClient.onRemoveConnection(connection);
    }
  }

  void onRestore() {
    if (isFinishInit) {
      mixPanelClient.onRestore();
    }
  }

  dynamic getConfig(String key, {dynamic defaultValue}) {
    return mixPanelClient.getConfig(key, defaultValue: defaultValue);
  }

  Future<void> setConfig(String key, dynamic value) async {
    await mixPanelClient.setConfig(key, value);
  }

  Future<void> onOpenApp() async {
    final weekStartAt = getConfig(MixpanelConfig.weekStartAt,
        defaultValue: DateTime.now().startDayOfWeek) as DateTime;
    final countUseAutonomyInWeek =
        getConfig(MixpanelConfig.countUseAutonomyInWeek, defaultValue: 0)
            as int;
    final now = DateTime.now();
    final startDayOfWeek = now.startDayOfWeek;
    if (startDayOfWeek.isAfter(weekStartAt.add(const Duration(days: 7)))) {
      addEvent(MixpanelEvent.numberUseAppInAWeek, data: {
        "number": countUseAutonomyInWeek,
        MixpanelEventProp.time: weekStartAt,
      });
      await setConfig(MixpanelConfig.weekStartAt, startDayOfWeek);
      await setConfig(MixpanelConfig.countUseAutonomyInWeek, 0);
    }
  }

  Future<void> onUseAppInForeground() async {
    final countUseAutonomyInWeek =
        getConfig(MixpanelConfig.countUseAutonomyInWeek, defaultValue: 0)
            as int;
    final countUseApp = countUseAutonomyInWeek + 1;
    await setConfig(MixpanelConfig.countUseAutonomyInWeek, countUseApp);
  }
}
