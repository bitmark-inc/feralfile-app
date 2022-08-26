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
import '../pages/settings_page.dart';
import '../test_data/test_configurations.dart';

void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Create a new full account", () {
    setUpAll(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(Duration(seconds: 30));
    });

    tearDownAll(() async {
      await driver.quit();
    });

    test('connect to server', () async {
      await driver.app.activate(METAMASK_APPPACKAGE);

      await driver.app.activate(AUTONOMY_APPPACKAGE);

      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings->+ Account");

      Future<String> metaAccountAliasf = genTestDataRandom("Meta");
      String metaAccountAlias = await metaAccountAliasf;

      await addExistingMetaMaskAccount(driver, "app", metaAccountAlias);

      int isCreatedMetaMaskAcc = await driver
          .findElements(AppiumBy.xpath(
              "//android.view.View[contains(@content-desc,'$metaAccountAlias')]"))
          .length;
      expect(isCreatedMetaMaskAcc, 1);
    });
  }, timeout: Timeout.none);
}
