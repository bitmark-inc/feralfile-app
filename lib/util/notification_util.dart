import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<bool> registerPushNotifications({bool askPermission = false}) async {
  log.info("register notification");
  if (askPermission) {
    final permission = Platform.isAndroid
        ? true
        : await OneSignal.shared.promptUserForPushNotificationPermission();

    if (!permission) {
      return false;
    }
  }

  try {
    final environment = await getAppVariant();
    final identityHash = (await injector<IAPApi>()
            .generateIdentityHash({"environment": environment}))
        .hash;
    final defaultDID =
        await (await injector<AccountService>().getDefaultAccount())
            .getAccountDID();
    await OneSignal.shared.setExternalUserId(defaultDID, identityHash);
    injector<ConfigurationService>().setNotificationEnabled(true);
    return true;
  } catch (error) {
    log.warning("error when registering notifications: $error");
    return false;
  }
}

Future<void> deregisterPushNotification() async {
  log.info("unregister notification");
  await OneSignal.shared.removeExternalUserId();
}
