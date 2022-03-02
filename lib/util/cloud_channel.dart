import 'package:flutter/services.dart';
import 'dart:io';

class CloudChannel {
  static const MethodChannel _channel = const MethodChannel('cloud');
  static const EventChannel _eventChannel = const EventChannel('cloud/event');

  final CloudHandler handler;

  CloudChannel({required this.handler}) {
    listen();
  }

  void listen() async {
    // TODO: Update observeAccountStatus for Android
    if (Platform.isAndroid) {
      handler.observeCloudStatus(true);
    } else if (Platform.isIOS) {
      await for (Map event in _eventChannel.receiveBroadcastStream()) {
        var params = event['params'];

        switch (event['eventName']) {
          case 'observeCloudAvailablity':
            final bool isAvailable = params['isAvailable'];

            handler.observeCloudStatus(isAvailable);
            break;

          default:
            break;
        }
      }
    }
  }
}

abstract class CloudHandler {
  void observeCloudStatus(bool isAvailable);
}
