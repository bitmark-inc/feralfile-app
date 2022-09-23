//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_configurations.dart';

void main() {
  late AppiumWebDriver driver;
  final dir = Directory.current;
  group("Setting Footer Test", () {
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

    test("Version", () async {
      try {
        await onBoardingSteps(driver);

        await selectSubSettingMenu(driver, "Settings");

        await scrollUntil(driver, "Version");

        var versionEle = await driver.findElement(AppiumBy.xpath(
            "//android.view.View[contains(@content-desc,'Version')]"));

        String versionStr = await versionEle.attributes['content-desc'];

        RegExp versionExp = RegExp(r'[0-9]+.[0-9]+.[0-9]+');

        var version = await versionExp.stringMatch(versionStr);

        await selectSubSettingMenu(driver, "Release notes");

        var hasVersion = await driver
            .findElements(AppiumBy.xpath(
            "//android.view.View[contains(@content-desc, '$version')]"))
            .length;

        expect(hasVersion, 1);
      } catch (e) {
        await captureScreen(driver);
      }
    });

    test("Privacy Policy", () async {
      try {
        // Open App at Home Page
        await onBoardingSteps(driver);

        await selectSubSettingMenu(driver, "Settings");

        await scrollUntil(driver, "Privacy Policy");

        await selectSubSettingMenu(driver, "Privacy Policy");

        int hasPrivacyPolicy = await driver
            .findElements(AppiumBy.xpath(
            "//android.view.View[@content-desc='Autonomy Privacy Policy']"))
            .length;

        expect(hasPrivacyPolicy, 1);

        await driver.back();

        var hasPrivacyAndPolicy = await driver
            .findElements(AppiumBy.accessibilityId("Privacy Policy"))
            .length;
        expect(hasPrivacyAndPolicy, 1);
      } catch (e) {
        await captureScreen(driver);
      }
    });
  }, timeout: Timeout.none);
}