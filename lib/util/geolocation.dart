//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart' as postcard;
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/number_utils.dart';
import 'package:autonomy_flutter/util/position_utils.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'log.dart';

Future<bool> checkLocationPermissions() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return false;
  }
  return true;
}

Future<Position> _getGeoLocation(
    {Duration timeout = const Duration(seconds: 10)}) async {
  Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium)
      .timeout(timeout);
  return position.copyWith(
      latitude: position.latitude.floorAtDigit(coordinate_digit_number),
      longitude: position.longitude.floorAtDigit(coordinate_digit_number));
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
          await _getGeoLocation(timeout: const Duration(seconds: 2));
      // if (location.isMocked) {
      //   UIHelper.showMockedLocation(
      //       navigationService.navigatorKey.currentContext!);
      //   return null;
      // }
      log.info("Location: ${location.latitude}, ${location.longitude}");
      final placeMark = await getPlaceMarkFromCoordinates(
          location.latitude, location.longitude);
      if (placeMark == null) {
        return null;
      }
      final address = getLocationName(placeMark);
      final geolocation = isFuzzy
          ? await getFuzzyGeolocation(address, location)
          : GeoLocation(position: location.toLocation(), address: address);
      log.info(
          "Fuzzy Location: ${geolocation.position.lat}, ${geolocation.position.lon}");
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
          position: position.toLocation().copyWith(
              latitude: location.latitude.floorAtDigit(coordinate_digit_number),
              longitude:
                  location.longitude.floorAtDigit(coordinate_digit_number)),
          address: address);
    }
  } catch (_) {}
  return GeoLocation(
      position: position.toLocation().copyWith(
          latitude: position.latitude.floorAtDigit(2),
          longitude: position.longitude.floorAtDigit(2)),
      address: address);
}

bool isValidLocation(Location position, double latitude, double longitude) {
  return (position.latitude - latitude).abs() < 0.2 &&
      (position.longitude - longitude).abs() < 0.2;
}

class GeoLocation {
  final postcard.Location position;
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

  postcard.Location toLocation() {
    return postcard.Location(lat: latitude, lon: longitude);
  }
}

extension LocationExtension on postcard.Location {
  postcard.Location copyWith(
      {required double latitude, required double longitude}) {
    return postcard.Location(lat: latitude, lon: longitude);
  }
}
