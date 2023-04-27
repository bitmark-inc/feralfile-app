//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:ui';

class DistanceFormatter {
  final Locale locale;

  //function convert kms to miles
  double convertKmToMiles(double km) {
    return km * 0.621371;
  }

  // check is miles or km
  bool isMiles() {
    final imperialSystemCountries = ['us', 'gb', 'lr', 'mm'];
    return imperialSystemCountries.contains(locale.countryCode);
  }

  DistanceFormatter({required this.locale});

  String format({double? distance, withFullName = false}) {
    if (distance == null) {
      return '-';
    }
    if (withFullName) {
      if (isMiles()) {
        return '${convertKmToMiles(distance).toStringAsFixed(0)} miles';
      }
      return '${distance.toStringAsFixed(0)} kilometers';
    }

    if (isMiles()) {
      return '${convertKmToMiles(distance).toStringAsFixed(0)} mi';
    }
    return '${distance.toStringAsFixed(0)} km';
  }
}
