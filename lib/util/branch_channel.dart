//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/services.dart';

class BranchChannel {
  static const EventChannel _eventChannel = EventChannel('branch.io/event');

  final BranchHandler handler;

  BranchChannel({required this.handler}) {
    listen();
  }

  void listen() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      handler.observeDeeplinkParams(event['params']);
    }
  }
}

abstract class BranchHandler {
  void observeDeeplinkParams(dynamic params);
}
