import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';
import 'package:sentry/sentry.dart';

class ChannelService {
  final iosWalletChannel = MethodChannel('com.feralfile.wallet');
  final androidWalletChannel = MethodChannel('com.feralfile.wallet');

  MethodChannel _getWalletChannel() {
    if (Platform.isAndroid) {
      return androidWalletChannel;
    }
    return iosWalletChannel;
  }

  Future<Map<String, List<String>>> exportMnemonicForAllPersonaUUIDs() async {
    try {
      final channel = _getWalletChannel();
      final r = await channel.invokeMethod('exportMnemonicForAllPersonaUUIDs');
      final seedMap = Map<String, dynamic>.from(r as Map).map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
      log.info('exportMnemonicForAllPersonaUUIDs: ${seedMap.keys.toString()}');
      return seedMap;
    } catch (e) {
      log.info('exportMnemonicForAllPersonaUUIDs error: $e');
      unawaited(Sentry.captureException(
          'exportMnemonicForAllPersonaUUIDs error: $e'));
      return {};
    }
  }

  Future<void> cleanMnemonicForAllPersonaUUIDs() async {
    final channel = _getWalletChannel();
    await channel.invokeMethod('cleanMnemonicForAllPersonaUUIDs');
  }
}
