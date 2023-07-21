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

  String format({double? distance, withFullName = false}) {
    if (distance == null) {
      return '-';
    }
    if (withFullName) {
      if (isMiles()) {
        return '${_numberFormat.format(distance)} miles';
      }
      return '${_numberFormat.format(distance)} kilometers';
    }

    if (isMiles()) {
      return '${_numberFormat.format(convertKmToMiles(distance))} mi';
    }
    return '${_numberFormat.format(distance)} km';
  }

  String showDistance({required double distance, DistanceUnit distanceUnit = DistanceUnit.km}) {
    if (distanceUnit == DistanceUnit.mile) {
      return '${_numberFormat.format(convertKmToMiles(distance))} mi';
    }
    return '${_numberFormat.format(distance)} km';
  }
}
