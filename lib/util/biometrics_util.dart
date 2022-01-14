import 'package:local_auth/local_auth.dart';

Future<bool> authenticateIsAvailable() async {
  LocalAuthentication localAuth = LocalAuthentication();
  final isAvailable = await localAuth.canCheckBiometrics;
  final isDeviceSupported = await localAuth.isDeviceSupported();
  return isAvailable && isDeviceSupported;
}