//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../pages/onboarding_page.dart';
import '../test_data/test_configurations.dart';
import '../pages/customer_support_page.dart';


void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Customer Support", () {
    setUp(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 30));
    });

    tearDown(() async {
      await driver.app.remove(AUTONOMY_APPPACKAGE);
      await driver.quit();
    });

    test('Request a feature', () async {
      await onBoardingSteps(driver);


    });
    test('Report a bug', () async {
      await onBoardingSteps(driver);
      await testSupportSubMenu(driver, 'Report a bug');
    });

    test('Share feedback', () async {
      await onBoardingSteps(driver);
      await testSupportSubMenu(driver, 'Share feedback');
    });

    test('Something else?', () async {
      await onBoardingSteps(driver);
      await testSupportSubMenu(driver, 'Something else');
    });



  }, timeout: Timeout.none);
}
