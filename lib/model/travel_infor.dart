//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/position_utils.dart';

class TravelInfo {
  final UserLocations from;
  final UserLocations? to;
  final int index;
  String? sentLocation;
  String? receivedLocation;

  TravelInfo(this.from, this.to, this.index,
      {this.sentLocation, this.receivedLocation});

  TravelInfo copyWith({
    UserLocations? from,
    UserLocations? to,
    int? index,
    String? sentLocation,
    String? receivedLocation,
  }) {
    return TravelInfo(
      from ?? this.from,
      to ?? this.to,
      index ?? this.index,
      sentLocation: sentLocation ?? this.sentLocation,
      receivedLocation: receivedLocation ?? this.receivedLocation,
    );
  }

  double? getDistance() {
    if (to == null) {
      return null;
    }

    if (from.stampedLocation!.isInternet || to!.claimedLocation!.isInternet) {
      return null;
    }

    return _getDistanceFromLatLonInKm(
        from.stampedLocation!.lat!,
        from.stampedLocation!.lon!,
        to!.claimedLocation!.lat!,
        to!.claimedLocation!.lon!);
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
    final stampedLocation = from.stampedLocation;
    if (stampedLocation == null || stampedLocation.isInternet) {
      sentLocation = internetUserGeoLocation.address;
      return;
    }
    sentLocation = await getLocationNameFromCoordinates(
        stampedLocation.lat!, stampedLocation.lon!);
  }

  Future<void> _getReceivedLocation() async {
    if (to == null) {
      receivedLocation = null;
    } else {
      final claimedLocation = to!.claimedLocation;
      if (claimedLocation == null || claimedLocation.isInternet) {
        receivedLocation = internetUserGeoLocation.address;
        return;
      }
      receivedLocation = await getLocationNameFromCoordinates(
          claimedLocation.lat!, claimedLocation.lon!);
    }
  }

  Future<void> getLocationName() async {
    await _getSentLocation();
    await _getReceivedLocation();
  }
}

extension ListTravelInfo on List<TravelInfo> {
  double? get totalDistance {
    if (isEmpty) {
      return null;
    }
    double totalDistance = 0;
    for (var travelInfo in this) {
      totalDistance += travelInfo.getDistance() ?? 0;
    }
    return totalDistance;
  }

  TravelInfo get notSentTravelInfo {
    if (isEmpty) {
      return TravelInfo(UserLocations(), null, 1,
          sentLocation: moMAGeoLocation.address);
    }
    final lastTravelInfo = last;
    return TravelInfo(lastTravelInfo.to!, null, lastTravelInfo.index + 1,
        sentLocation: lastTravelInfo.receivedLocation);
  }

  TravelInfo get sendingTravelInfo {
    if (isEmpty) {
      return TravelInfo(UserLocations(), null, 1, sentLocation: "MoMA");
    }
    final lastTravelInfo = last;
    return TravelInfo(lastTravelInfo.to!, null, lastTravelInfo.index + 1,
        sentLocation: lastTravelInfo.receivedLocation);
  }
}
