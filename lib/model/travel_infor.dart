//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/util/position_utils.dart';

class TravelInfo {
  final LocationInformation from;
  final LocationInformation? to;
  final int index;
  String? sentLocation;
  String? receivedLocation;

  TravelInfo(this.from, this.to, this.index,
      {this.sentLocation, this.receivedLocation});

  double? getDistance() {
    if (to == null) {
      return null;
    }
    return _getDistanceFromLatLonInKm(
        from.stampedLocation!.lat,
        from.stampedLocation!.lon,
        to!.claimedLocation!.lat,
        to!.claimedLocation!.lon);
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
    if (from.stampedLocation != null) {
      sentLocation = await getLocationNameFromCoordinates(
          from.stampedLocation!.lat, from.stampedLocation!.lon);
    }
  }

  Future<void> _getReceivedLocation() async {
    if (to == null) {
      receivedLocation = null;
    } else {
      receivedLocation = await getLocationNameFromCoordinates(
          to!.claimedLocation!.lat, to!.claimedLocation!.lon);
    }
  }

  Future<void> getLocationName() async {
    await _getSentLocation();
    await _getReceivedLocation();
  }
}

class LocationInformation {
  final Location? claimedLocation;
  final Location? stampedLocation;

  // constructor
  LocationInformation({this.claimedLocation, this.stampedLocation});

  // factory constructor
  factory LocationInformation.fromJson(Map<String, dynamic> json) {
    return LocationInformation(
      claimedLocation: json['claimedLocation'] == null
          ? null
          : Location.fromJson(json['claimedLocation'] as Map<String, dynamic>),
      stampedLocation: json['stampedLocation'] == null
          ? null
          : Location.fromJson(json['stampedLocation'] as Map<String, dynamic>),
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'claimedLocation': claimedLocation?.toJson(),
      'stampedLocation': stampedLocation?.toJson(),
    };
  }
}

class Location {
  final double lat;
  final double lon;

  // constructor
  Location({required this.lat, required this.lon});

  // factory constructor
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
        lat: double.parse(json['lat'].toString()),
        lon: double.parse(json['lon'].toString()));
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
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
