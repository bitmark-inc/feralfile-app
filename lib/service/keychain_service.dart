//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:flutter/services.dart';

class KeychainService {
  static const MethodChannel _channel = MethodChannel('keychain');

  Future<dynamic> getAllKeychainItems() async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod('getAllKeychainItems');
    }
    return [];
  }

  Future<void> removeKeychainItems({String? account, String? service}) {
    if (Platform.isIOS) {
      return _channel.invokeMethod('removeKeychainItems', {
        'account': account,
        'service': service,
      });
    }
    return Future.value();
  }
}
