//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class CloudChannel {
  static const EventChannel _eventChannel = EventChannel('cloud/event');

  final CloudHandler handler;

  CloudChannel({required this.handler}) {
    unawaited(listen());
  }

  Future<void> listen() async {
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
