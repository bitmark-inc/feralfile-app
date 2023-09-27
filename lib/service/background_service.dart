//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'dart:async';

import 'package:autonomy_flutter/gateway/crowd_sourcing_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class BackgroundService {
  final ConfigurationService _configurationService;
  final CrowdSourcingApi _crowdSourcingApi;

  BackgroundService(this._configurationService, this._crowdSourcingApi);

  Future configureBackgroundTask() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 60,
          stopOnTerminate: false,
          enableHeadless: true,
        ), (String taskId) async {
      // <-- Event callback.
      log.info("[BackgroundService] taskId: $taskId");

      if (taskId == packageInfo.packageName) {
        await mimeTypeUpdateWorkflow();
      }

      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // <-- Event timeout callback
      log.info("[BackgroundService] TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });

    startMIMETypeUpdateTask();
    startExpiredPostcardSharedLinkNotificationTask();
  }

  // [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
  // Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
  @pragma('vm:entry-point')
  void backgroundFetchHeadlessTask(HeadlessTask task) async {
    String taskId = task.taskId;
    bool isTimeout = task.timeout;
    if (isTimeout) {
      // This task has exceeded its allowed running-time.
      // You must stop what you're doing and immediately .finish(taskId)
      log.info("[BackgroundService] Headless task timed-out: $taskId");
      BackgroundFetch.finish(taskId);
      return;
    }

    log.info('[BackgroundService] Headless event received.');
    await mimeTypeUpdateWorkflow();

    BackgroundFetch.finish(taskId);
  }

  Future startMIMETypeUpdateTask() async {
    if (!_configurationService.allowContribution()) {
      return;
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    log.info(
        "[BackgroundService] register service: ${packageInfo.packageName}");
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: packageInfo.packageName,
        delay: 86400000, // <-- 1 day in milliseconds
        periodic: true,
        requiresNetworkConnectivity: true));
  }

  Future startExpiredPostcardSharedLinkNotificationTask() async {
    if (!(_configurationService.isNotificationEnabled() ?? false)) {
      return;
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    log.info(
        "[BackgroundService] register service: ${packageInfo.packageName}.notification");
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "${packageInfo.packageName}.notification",
        delay: 10800000, // <-- 3h in milliseconds
        periodic: true,
        requiresNetworkConnectivity: true));
  }

  Future mimeTypeUpdateWorkflow() async {
    if (!_configurationService.allowContribution()) {
      return;
    }

    log.info('[BackgroundService] mimeTypeUpdateWorkflow started.');

    final response = await _crowdSourcingApi.getTokenFeedbacks();

    List<Map<String, dynamic>> tokens = [];

    for (final token in response.tokens) {
      final uri = Uri.tryParse(token.previewURL);
      if (uri == null) continue;

      try {
        final res = await http.head(uri);
        tokens.add({
          "indexID": token.indexID,
          "mimeType": res.headers["content-type"],
        });
      } catch (e) {
        log.info('[BackgroundService] error getting mimeType for $uri.');
      }
    }

    await _crowdSourcingApi.sendTokenFeedback({
      "requestID": response.requestID,
      "tokens": tokens,
    });

    log.info('[BackgroundService] mimeTypeUpdateWorkflow finished.');
  }
}
