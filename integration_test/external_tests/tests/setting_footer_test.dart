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
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");

      await scrollSettingPage(driver);

      var versionEle = await driver.findElement(AppiumBy.xpath(
          "//android.view.View[contains(@content-desc,'Version')]"));

      String versionStr = await versionEle.attributes['content-desc'];

      RegExp versionExp = RegExp(r'[0-9]+.[0-9]+.[0-9]+');

      var version = await versionExp.stringMatch(versionStr);

      await selectSubSettingMenu(driver, "Release notes");

      var hasVersion = await driver.findElements(AppiumBy.xpath(
          "//android.view.View[contains(@content-desc, '$version')]")).length;

      expect(hasVersion, 1);
    });

    test("EULA", () async {
      // Open App at Home Page
      await onBoardingSteps(driver);

      // GO to Settings Page
      await selectSubSettingMenu(driver, "Settings");

      // Scroll Down
      await scrollSettingPage(driver);

      await selectSubSettingMenu(driver, "EULA");

      int hasLicense = await driver.findElements(AppiumBy.xpath(
        "//android.view.View[@content-desc='Autonomy End User License Agreement']"
      )).length;

      expect(hasLicense, 1);

      //var backBtn = await driver.findElement(
      //    AppiumBy.accessibilityId("BACK"));
      //String attr = await backBtn.attributes["content-desc"];
      //await backBtn.click();
      //print("Clicked");

      /*
      var selector = 'new UiSelector().className("android.widget.ImageView").index(0)';
      var backBtnUIAutomator = 'UiCollection($selector).click()';
      var finder = await AppiumBy.uiautomator(backBtnUIAutomator);
      var c = await driver.findElement(finder);
      print(await c.attributes['content-desc']);
      c.click();

       */
      await driver.back();

      //await selectSubSettingMenu(driver, "Privacy Policy");
      var hasEULA = await driver.findElements(
              AppiumBy.accessibilityId("EULA")).length;
      expect(hasEULA, 1);
    });

    test("Privacy Policy", () async {
      // Open App at Home Page
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");

      await scrollSettingPage(driver);

      await selectSubSettingMenu(driver, "Privacy Policy");

      int hasPrivacyPolicy = await driver.findElements(AppiumBy.xpath(
      "//android.view.View[@content-desc='Autonomy Privacy Policy']"
      )).length;

      expect(hasPrivacyPolicy, 1);

      await driver.back();

      var hasPrivacyAndPolicy = await driver.findElements(
              AppiumBy.accessibilityId("Privacy Policy")).length;
      expect(hasPrivacyAndPolicy, 1);
    });


  }, timeout: Timeout.none);
}
