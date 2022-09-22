//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// import 'dart:html';
import 'dart:io';

import 'package:appium_driver/async_io.dart';

import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../pages/exchanges_page.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_configurations.dart';
import '../test_data/test_constants.dart';

void main() {
  late AppiumWebDriver driver;

  final dir = Directory.current;
  group("Link wallet to", () {
    setUp(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: CHROME_MOBILE_BROWSER_PROFILE(dir.path));

      await driver.timeouts.setPageLoadTimeout(Duration(seconds: 20));

      // sleep(Duration(seconds: 5));
      String path = dir.path;
      await driver.app.install(
          "$path/build/app/outputs/flutter-apk/app-inhouse-release.apk");
      await driver.app.activate(AUTONOMY_APPPACKAGE);
      sleep(Duration(seconds: 2));
      await driver.contexts.setContext("NATIVE_APP");
      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 20));
    });

    tearDown(() async {
      await driver.app.remove(AUTONOMY_APPPACKAGE);

      driver.app.reset();

      await driver.quit();
    });

    for (var exchange in LIST_OF_EXCHANGES) {
      test(exchange["exchangeName"] ?? "", () async {
        try {
          await onBoardingSteps(driver);

          await linkBeaconWalletFromExchange(
              driver, exchange["exchangeName"] ?? "");

          int isWalletLinked = await driver
              .findElements(AppiumBy.accessibilityId(
                  exchange["linkedExchangeName"] ?? ""))
              .length;
          expect(isWalletLinked, 1);
        } catch (e) {
          await captureScreen(driver);
        }
      });

      /* This section is waiting for the bug https://github.com/bitmark-inc/autonomy-apps/issues/1690 is fixed. 
      Then we will implement the case connect app at the first time without onboarding to check the defer deep link 
      test(exchange["exchangeName"] ?? "", () async {
      }); */
    }
  }, timeout: Timeout.none);
}
