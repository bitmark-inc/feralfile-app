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
import '../test_data/test_constants.dart';

void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Import a full account by seeds", () {
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

    test('MetaMask', () async {
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings->+ Account");

      Future<String> metaAccountAliasf = genTestDataRandom("Meta");
      String metaAccountAlias = await metaAccountAliasf;

      await importAnAccountBySeeds(
          driver, "MetaMask", SEEDS_TO_RESTORE_FULLACCOUNT, metaAccountAlias);

      int isCreatedMetaMaskAcc = await driver
          .findElements(AppiumBy.xpath(
              "//android.view.View[contains(@content-desc,'$metaAccountAlias')]"))
          .length;
      expect(isCreatedMetaMaskAcc, 1);
    });

    test('Temple', () async {
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings->+ Account");

      Future<String> templeAccountAliasf = genTestDataRandom("Temple");
      String templeAccountAlias = await templeAccountAliasf;

      await importAnAccountBySeeds(
          driver, "Temple", SEED_TO_RESTORE_TEMPLE, templeAccountAlias);

      int isCreatedMetaMaskAcc = await driver
          .findElements(AppiumBy.xpath(
              "//android.view.View[contains(@content-desc,'$templeAccountAlias')]"))
          .length;
      expect(isCreatedMetaMaskAcc, 1);
    });

    test('Kukai', () async {
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings->+ Account");

      Future<String> kukaiAccountAliasf = genTestDataRandom("Kukai");
      String kukaiAccountAlias = await kukaiAccountAliasf;

      await importAnAccountBySeeds(
          driver, "MetaMask", SEED_TO_RESTORE_KUKAI, kukaiAccountAlias);

      int isCreatedMetaMaskAcc = await driver
          .findElements(AppiumBy.xpath(
              "//android.view.View[contains(@content-desc,'$kukaiAccountAlias')]"))
          .length;
      expect(isCreatedMetaMaskAcc, 1);
    });
  }, timeout: Timeout.none);
}
