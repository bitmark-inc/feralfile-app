//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final DateFormat dateFormatterYMDHM = DateFormat('yyyy-MMM-dd HH:mm', "en_US");
final DateFormat dateFormatterMDHM = DateFormat('dd MMMM, HH:mm', "en_US");
final DateFormat timeFormatterHM = DateFormat('HH:mm', "en_US");
final DateFormat dateFormatterMD = DateFormat('MMM-dd', "en_US");
final DateFormat dateFormatterYMD = DateFormat('yyyy-MMM-dd', "en_US");
final DateFormat dateFormatterWdHM = DateFormat('EEEE HH:mm', "en_US");

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

String getLocalTimeOnly(DateTime dateTime) {
  return timeFormatterHM.format(dateTime);
}

String getChatDateTimeRepresentation(DateTime dateTime) {
  final DateTime now = DateTime.now();
  if (DateUtils.isSameDay(dateTime, now)) {
    return "Today, ${timeFormatterHM.format(dateTime)}";
  }
  if (isInAWeekOffset(dateTime)) {
    return dateFormatterWdHM.format(dateTime.toLocal());
  }
  if (dateTime.year == now.year) {
    return dateFormatterMDHM.format(dateTime.toLocal());
  }
  return dateFormatterYMDHM.format(dateTime.toLocal());
}

bool isInAWeekOffset(DateTime datetime) {
  final now = DateTime.now();
  final offsetOneWeek = now.subtract(Duration(
      days: 6,
      hours: now.hour,
      minutes: now.minute,
      seconds: now.second,
      milliseconds: now.millisecond));
  return datetime.isAfter(offsetOneWeek);
}

extension DateTimeExt on DateTime {
  DateTime get startDayOfWeek {
    return DateTime.utc(year, month, day - weekday + 1);
  }
}
