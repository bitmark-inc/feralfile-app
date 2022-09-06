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
  group("Create a new full account", () {

    setUp(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 30));
    });

    tearDown(() async {
      //await driver.app.remove(AUTONOMY_APPPACKAGE);
      await driver.quit();
    });

    test("with alias and check balance", () async {
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

  }, timeout: Timeout.none);
}
