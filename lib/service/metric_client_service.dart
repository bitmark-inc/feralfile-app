import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:metric_client/metric_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class MetricClientService {
  final AccountService _accountService;

  MetricClientService(this._accountService);

  late DeviceConfig _deviceConfig;
  final mixPanelClient = injector<MixPanelClientService>();

  Future<void> initService() async {
    final root = await getTemporaryDirectory();
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

    mixPanelClient.initService();
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
    final defaultDID = (await (await _accountService.getCurrentDefaultAccount())
            ?.getAccountDID()) ??
        'unknown';
    final hashedUserID = sha224.convert(utf8.encode(defaultDID)).toString();
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
  }

  timerEvent(String name) {
    mixPanelClient.timerEvent(name.snakeToCapital());
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
}
