//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkLocationPermissions() async {
  await Geolocator.requestPermission();
  final status = await Permission.location.status;
  if (status.isDenied || status.isPermanentlyDenied) {
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
