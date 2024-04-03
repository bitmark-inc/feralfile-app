import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthenticationService {
  static Future<bool> checkLocalAuth() async {
    final configurationService = injector<ConfigurationService>();
    final isAvailable = await authenticateIsAvailable();
    final isDevicePasscodeEnabled =
        configurationService.isDevicePasscodeEnabled();

    if (isDevicePasscodeEnabled && isAvailable) {
      final localAuth = LocalAuthentication();
      bool didAuthenticate = false;
      try {
        didAuthenticate = await localAuth.authenticate(
          localizedReason: 'authen_for_autonomy'.tr(),
        );
      } catch (e) {
        log.info('authenticate error $e');
      }
      return didAuthenticate;
    }
    return true;
  }
}
