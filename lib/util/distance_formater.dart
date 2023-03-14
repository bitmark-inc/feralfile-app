//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:ui';

class DistanceFormatter {
  final Locale locale;

  DistanceFormatter({required this.locale});

  String format({required dynamic distance}) {
    return '${distance} mil';
  }
}
