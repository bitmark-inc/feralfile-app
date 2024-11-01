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
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry/sentry.dart';

Future<bool> registerPushNotifications({bool askPermission = false}) async {
  log.info('register notification');
  if (askPermission) {
    final permission = Platform.isAndroid
        ? true
        : await OneSignal.shared.promptUserForPushNotificationPermission();

    if (!permission) {
      return false;
    }
  }

  try {
    final identityHash = await OneSignalHelper.getIdentityHash();
    final primaryAddress = await injector<AddressService>().getPrimaryAddress();
    await OneSignal.shared.setExternalUserId(primaryAddress!, identityHash);
    await injector<ConfigurationService>().setNotificationEnabled(true);
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
  await OneSignal.shared.removeExternalUserId();
}

class OneSignalHelper {
  static Future<void> setExternalUserId(
      {required String userId, String? authHashToken}) async {
    await OneSignal.shared.setExternalUserId(userId, authHashToken);
  }

  static Future<String> getIdentityHash() async {
    final environment = await getAppVariant();
    return (await injector<IAPApi>()
            .generateIdentityHash({'environment': environment}))
        .hash;
  }
}
