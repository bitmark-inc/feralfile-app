//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:intl/intl.dart';

final DateFormat _localtimeFormatter = DateFormat('yyyy-MM-dd\nhh:mm:ss');

String localTimeString(DateTime date) {
  return _localtimeFormatter.format(date.toLocal());
}

String localTimeStringFromISO8601(String str) {
  final date = DateTime.parse(str);
  return localTimeString(date);
}
