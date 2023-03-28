//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
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
    {Duration timeout = const Duration(seconds: 10)}) async {
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
      List<Placemark> placeMarks = await placemarkFromCoordinates(
          location.latitude, location.longitude,
          localeIdentifier: "en_US");
      if (placeMarks.isEmpty) {
        return null;
      }
      return GeoLocation(position: location, placeMark: placeMarks.first);
    } catch (e) {
      await UIHelper.showWeakGPSSignal(
          navigationService.navigatorKey.currentContext!);
      return null;
    }
  }
}

class GeoLocation {
  final Position position;
  final Placemark placeMark;

  //constructor
  GeoLocation({required this.position, required this.placeMark});
}
