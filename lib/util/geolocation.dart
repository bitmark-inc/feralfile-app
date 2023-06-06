//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/position_utils.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

Future<bool> checkLocationPermissions() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return false;
  }
  return true;
}

Future<Position> getGeoLocation(
    {Duration timeout = const Duration(seconds: 10)}) async {
  Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium)
      .timeout(timeout);
  return position;
}

Future<GeoLocation?> getGeoLocationWithPermission(
    {Duration timeout = const Duration(seconds: 10),
    bool isFuzzy = true}) async {
  final hasPermission = await checkLocationPermissions();
  final navigationService = injector<NavigationService>();
  if (!hasPermission) {
    UIHelper.showDeclinedGeolocalization(
        navigationService.navigatorKey.currentContext!);
    return null;
  } else {
    try {
      final location =
          await getGeoLocation(timeout: const Duration(seconds: 2));
      if (location.isMocked) {
        UIHelper.showMockedLocation(
            navigationService.navigatorKey.currentContext!);
        return null;
      }
      final placeMark = await getPlaceMarkFromCoordinates(
          location.latitude, location.longitude);
      if (placeMark == null) {
        return null;
      }
      final address = getLocationName(placeMark);
      final geolocation = isFuzzy
          ? await getFuzzyGeolocation(address, location)
          : GeoLocation(position: location, address: address);

      return geolocation;
    } catch (e) {
      await UIHelper.showWeakGPSSignal(
          navigationService.navigatorKey.currentContext!);
      return null;
    }
  }
}

Future<GeoLocation> getFuzzyGeolocation(
    String address, Position position) async {
  try {
    final locations = await locationFromAddress(address);
    final location = locations.firstWhereOrNull((element) =>
        isValidLocation(element, element.latitude, element.longitude));
    if (location != null) {
      return GeoLocation(
          position: position.copyWith(
              latitude: location.latitude, longitude: location.longitude),
          address: address);
    }
  } catch (_) {}
  return GeoLocation(
      position: position.copyWith(
          latitude: double.parse(position.latitude.toStringAsFixed(2)),
          longitude: double.parse(position.longitude.toStringAsFixed(2))),
      address: address);
}

bool isValidLocation(Location position, double latitude, double longitude) {
  return (position.latitude - latitude).abs() < 0.2 &&
      (position.longitude - longitude).abs() < 0.2;
}

class GeoLocation {
  final Position position;
  final String address;

  //constructor
  GeoLocation({required this.position, required this.address});
}

extension PositionExtension on Position {
  Position copyWith({required double latitude, required double longitude}) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      accuracy: accuracy,
      altitude: altitude,
      heading: heading,
      speed: speed,
      speedAccuracy: speedAccuracy,
      floor: floor,
      isMocked: isMocked,
    );
  }
}
