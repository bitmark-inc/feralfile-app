//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

Random random = Random.secure();

String generateRandomString(int len) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => chars[random.nextInt(chars.length)])
      .join();
}

String generateRandomHex(int len) => List<String>.generate(
    len, (i) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
