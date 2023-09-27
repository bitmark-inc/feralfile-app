//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/service/locale_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DistanceFormatter {
  //function convert kms to miles
  double convertKmToMiles(double km) {
    return km * 0.621371;
  }

  final _numberFormat = NumberFormat("#,##0", "en_US");

  // check is miles or km
  static bool isMiles() {
    return LocaleService.measurementSystem == "imperial";
  }

  static DistanceUnit get getDistanceUnit {
    return isMiles() ? DistanceUnit.mile : DistanceUnit.km;
  }

  DistanceFormatter();

  String format({double? distance, withFullName = false, String? prefix}) {
    if (distance == null) {
      return '-';
    }
    String result = '';
    if (withFullName) {
      if (isMiles()) {
        result = "_miles"
            .tr(args: [_numberFormat.format(convertKmToMiles(distance))]);
      }
      result = "_kilometers".tr(args: [_numberFormat.format(distance)]);
    } else {
      if (isMiles()) {
        result =
            "_mi".tr(args: [_numberFormat.format(convertKmToMiles(distance))]);
      } else {
        result = "_km".tr(args: [_numberFormat.format(distance)]);
      }
    }
    result = prefix != null ? '$prefix $result' : result;
    return result;
  }

  String showDistance(
      {required double distance, DistanceUnit distanceUnit = DistanceUnit.km}) {
    if (distanceUnit == DistanceUnit.mile) {
      return '${_numberFormat.format(distance)} mi';
    }
    return '${_numberFormat.format(distance)} km';
  }
}
