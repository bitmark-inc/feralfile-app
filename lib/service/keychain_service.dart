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

  Future<void> clearKeychainItems() async {
    final secClasses = [
      KeychainSecClass.kSecClassGenericPassword,
      KeychainSecClass.kSecClassKey
    ];
    await Future.wait(
      secClasses.map(
        (secClass) => removeKeychainItems(
          secClass: secClass,
        ),
      ),
    );
  }

  Future<dynamic> getAllKeychainItems(
      {String? account, String? service}) async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod('getAllKeychainItems', {
        'account': account,
        'service': service,
      });
    }
    return [];
  }

  Future<void> removeKeychainItems(
      {required KeychainSecClass secClass, String? account, String? service}) {
    if (Platform.isIOS) {
      return _channel.invokeMethod('removeKeychainItems', {
        'account': account,
        'service': service,
        'secClass': secClass.value,
      });
    }
    return Future.value();
  }
}

enum KeychainSecClass {
  kSecClassGenericPassword,
  kSecClassKey,
  ;

  String get value {
    switch (this) {
      case KeychainSecClass.kSecClassGenericPassword:
        return 'genp';
      case KeychainSecClass.kSecClassKey:
        return 'keys';
    }
  }
}
