//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry/sentry.dart';

Future<bool> registerPushNotifications({bool askPermission = false}) async {
  log.info('register notification');
  if (askPermission) {
    final permission = Platform.isAndroid
        ? true
        : await OneSignal.Notifications.requestPermission(true);

    if (!permission) {
      return false;
    }
  }

  try {
    final userId = await injector<AuthService>().getUserId();
    await OneSignal.login(userId!);
    await OneSignal.User.pushSubscription.optIn();
    return true;
  } catch (error) {
    unawaited(Sentry.captureException(
        'error when registering notifications: $error'));
    log.warning('error when registering notifications: $error');
    return false;
  }
}

Future<void> deregisterPushNotification() async {
  log.info('unregister notification');
  await OneSignal.User.pushSubscription.optOut();
  await OneSignal.logout();
}

class OneSignalHelper {
  static Future<void> setExternalUserId(
      {required String userId, String? authHashToken}) async {
    await OneSignal.login(userId);
  }

  static Future<String> getIdentityHash() async {
    final environment = await getAppVariant();
    return (await injector<IAPApi>()
            .generateIdentityHash({'environment': environment}))
        .hash;
  }
}
