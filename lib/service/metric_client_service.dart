import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:metric_client/metric_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class MetricClientService {
  final AccountService _accountService;
  late Timer? useAppTimer;

  MetricClientService(this._accountService);

  late DeviceConfig _deviceConfig;
  final mixPanelClient = injector<MixPanelClientService>();
  bool isFinishInit = false;

  Future<void> initService() async {
    final root = await getTemporaryDirectory();
    useAppTimer = Timer.periodic(USE_APP_MIN_DURATION, (timer) async {
      timer.cancel();
      await onUseAppInForeground();
    });
    await MetricClient.init(
      storageOption: StorageOption(
        name: 'metric',
        path: '${root.path}/metric',
      ),
      apiOption: APIOption(
        endpoint: Environment.metricEndpoint,
        secret: Environment.metricSecretKey,
      ),
    );
    final deviceID = await getDeviceID() ?? "unknown";
    final hashedDeviceID = sha224.convert(utf8.encode(deviceID)).toString();
    final packageInfo = await PackageInfo.fromPlatform();
    final isAppcenterBuild = await isAppCenterBuild();

    _deviceConfig = DeviceConfig(
      deviceId: hashedDeviceID,
      platform: Platform.operatingSystem,
      version: packageInfo.version,
      internalBuild: isAppcenterBuild,
    );

    await mixPanelClient.initService();
    isFinishInit = true;
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
    final defaultAccount = await _accountService.getCurrentDefaultAccount();
    final defaultDID = (await defaultAccount?.getAccountDID()) ?? 'unknown';
    final hashedUserID = sha224.convert(utf8.encode(defaultDID)).toString();
    if (isFinishInit) {
      MetricClient.addEvent(
        name,
        message: message,
        userId: hashedUserID,
        data: data,
        hashedData: hashedData,
        deviceConfig: _deviceConfig,
      );

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
        await MetricClient.sendMetrics();
        await mixPanelClient.sendData();
      }
      await MetricClient.clear();
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

  MixpanelConfig getConfig() {
    return mixPanelClient.getConfig();
  }

  Future<void> setConfig(MixpanelConfig config) async {
    await mixPanelClient.setConfig(config);
  }

  Future<void> onUseAppInForeground() async {
    final config = getConfig();
    final now = DateTime.now();
    final startDayOfWeek = now.startDayOfWeek;
    if (startDayOfWeek.compareTo(config.weekStartAt) != 0) {
      final newConfig = config.copyWith(
        weekStartAt: startDayOfWeek,
        countUseAutonomyInWeek: 1,
      );
      await setConfig(newConfig);
      return;
    }
    final countUseApp = config.countUseAutonomyInWeek + 1;
    if (countUseApp == 3) {
      addEvent(MixpanelEvent.numberUseAppInAWeek, data: {
        "number": countUseApp,
      });
    }
    final newConfig = config.copyWith(countUseAutonomyInWeek: countUseApp);
    await setConfig(newConfig);
  }
}
