import 'package:autonomy_flutter/util/log.dart';
import 'package:local_auth/local_auth.dart';

Future<bool> authenticateIsAvailable() async {
  LocalAuthentication localAuth = LocalAuthentication();
  final isAvailable = await localAuth.canCheckBiometrics;
  final isDeviceSupported = await localAuth.isDeviceSupported();
  log.info(
      "authenticateIsAvailable: isAvailable = $isAvailable, isDeviceSupported = $isDeviceSupported");
  return isAvailable && isDeviceSupported;
}
