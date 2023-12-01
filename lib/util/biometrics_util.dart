//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/log.dart';
import 'package:local_auth/local_auth.dart';

Future<bool> authenticateIsAvailable() async {
  LocalAuthentication localAuth = LocalAuthentication();
  final isDeviceSupported = await localAuth.isDeviceSupported();
  log.info('authenticateIsAvailable: isDeviceSupported = $isDeviceSupported');
  return isDeviceSupported;
}
