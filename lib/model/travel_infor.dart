//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/util/geolocation.dart';

class TravelInfo {
  GeoLocation from;
  GeoLocation to;
  final int index;

  TravelInfo(
    this.from,
    this.to,
    this.index,
  );

  TravelInfo copyWith({
    GeoLocation? from,
    GeoLocation? to,
    int? index,
    String? sentLocation,
    String? receivedLocation,
  }) {
    return TravelInfo(
      from ?? this.from,
      to ?? this.to,
      index ?? this.index,
    );
  }

  double? getDistance() {
    if (from.isInternet || to.isInternet) {
      return 0;
    }
    if (from.position.isNull || to.position.isNull) {
      return null;
    }

    return _getDistanceFromLatLonInKm(
      from.position.lat!,
      from.position.lon!,
      to.position.lat!,
      to.position.lon!,
    );
  }

  // get distance from longitude and latitude
  double _getDistanceFromLatLonInKm(
      double lat1, double lon1, double lat2, double lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat2 - lat1); // deg2rad below
    var dLon = deg2rad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // Distance in km
    return d;
  }

  // convert degree to radian
  double deg2rad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _getSentLocation() async {
    await from.getAddress();
  }

  Future<void> _getReceivedLocation() async {
    await to.getAddress();
  }

  Future<void> getLocationName() async {
    await _getSentLocation();
    await _getReceivedLocation();
  }
}

extension ListTravelInfo on List<TravelInfo> {
  double get totalDistance {
    double totalDistance = 0;
    for (var travelInfo in this) {
      totalDistance += travelInfo.getDistance() ?? 0;
    }
    return totalDistance;
  }
}
