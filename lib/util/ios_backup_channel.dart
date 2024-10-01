import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';

class IOSBackupChannel {
  static const MethodChannel _channel = MethodChannel('migration_util');

  Future<List<String>> getUUIDsFromKeychain() async {
    final keychainUUIDs =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});
    log.info('keychainUUIDs: $keychainUUIDs');

    final List<String> personaUUIDs = (keychainUUIDs as List<dynamic>)
        .map((e) => e.toString())
        .map((e) => e.toLowerCase())
        .toList()
      ..removeWhere((element) => element.isEmpty);
    return personaUUIDs;
  }

  Future<String?> getBackupDeviceID() async {
    final String? deviceId = await _channel.invokeMethod('getDeviceID', {});
    return deviceId;
  }
}
