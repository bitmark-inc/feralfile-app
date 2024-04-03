import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthenticationService {
  static Future<bool> checkLocalAuth() async {
    final isAvailable = await authenticateIsAvailable();
    final isDevicePasscodeEnabled = await LibAukDart.isBiometricEnabled();

    if (isDevicePasscodeEnabled && isAvailable) {
      final localAuth = LocalAuthentication();
      bool didAuthenticate = false;
      try {
        didAuthenticate = await localAuth.authenticate(
          localizedReason: "authen_for_autonomy".tr(),
        );
      } catch (e) {
        log.info(e);
      }
      return didAuthenticate;
    }
    return true;
  }
}
