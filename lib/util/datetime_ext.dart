//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final DateFormat dateFormatterYMDHM = DateFormat('yyyy-MMM-dd HH:mm', "en_US");
final DateFormat dateFormatterMDHM = DateFormat('MMM-dd HH:mm', "en_US");
final DateFormat timeFormatterHM = DateFormat('HH:mm', "en_US");
final DateFormat dateFormatterMD = DateFormat('MMM-dd', "en_US");
final DateFormat dateFormatterYMD = DateFormat('yyyy-MMM-dd', "en_US");

String localTimeString(DateTime date) {
  return dateFormatterYMDHM.format(date.toLocal()).toUpperCase();
}

String localTimeStringFromISO8601(String str) {
  final date = DateTime.parse(str);
  return localTimeString(date);
}

// From chat_ui/util
String getVerboseDateTimeRepresentation(DateTime dateTime) {
  final DateTime now = DateTime.now();
  if (DateUtils.isSameDay(dateTime, now)) {
    return timeFormatterHM.format(dateTime);
  }
  if (dateTime.year == now.year) {
    return dateFormatterMD.format(dateTime).toUpperCase();
  }
  return dateFormatterYMDHM.format(dateTime).toUpperCase();
}

String getChatDateTimeRepresentation(DateTime dateTime) {
  final DateTime now = DateTime.now();
  if (DateUtils.isSameDay(dateTime, now)) {
    return timeFormatterHM.format(dateTime);
  }
  if (dateTime.year == now.year) {
    return dateFormatterMDHM.format(dateTime.toLocal()).toUpperCase();
  }
  return dateFormatterYMDHM.format(dateTime.toLocal()).toUpperCase();
}

extension DateTimeExt on DateTime {
  DateTime get startDayOfWeek {
    return DateTime.utc(year, month, day - weekday + 1);
  }
}
