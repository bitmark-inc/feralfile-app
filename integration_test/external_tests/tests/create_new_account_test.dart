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
import '../pages/onboarding_page.dart' as Onboarding;
import '../test_data/test_configurations.dart';
import '../pages/settings_page.dart';

void main() {
  late AppiumWebDriver driver;
  final dir = Directory.current;
  group("Create new account", () {

    setUp(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 5));
    });

    tearDown(() async {
      await driver.app.remove(AUTONOMY_APPPACKAGE);
      await driver.quit();
    });

    test("with alias and check balance", () async {
      await Onboarding.onBoardingSteps(driver);
      await selectSubSettingMenu(driver, "Settings->+ Account");

      var newButton = await getElementByContentDesc(driver, 'New');
      await newButton.click();

      var continueButton = await driver.findElement(continueButtonLocator);
      await continueButton.click();

      String userAlias = 'Alias';

      AppiumBy enterAliasLocator = AppiumBy.className('android.widget.EditText');
      var enterAlias = await driver.findElement(enterAliasLocator);
      await enterAlias.click();
      await enterAlias.sendKeys(userAlias);
      await driver.keyboard.sendKeys('\n');

      var saveButton = await driver.findElement(saveAliasButtonLocator);
      await saveButton.click();

      int isContinueWithoutButtonExist =
      await driver.findElements(continueWithouItbuttonLocation).length;
      if (isContinueWithoutButtonExist == 1) {
        var continueWithoutItButton =
        await driver.findElement(continueWithouItbuttonLocation);
        await continueWithoutItButton.click();
      } else {
        continueButton = await driver.findElement(continueButtonLocator);
        await continueButton.click();
      }

      // Check Alias
      var newAlias = await driver.findElements(AppiumBy.accessibilityId('$userAlias'));
      expect(await newAlias.length, 1);

      // Check Balance
      var first =  await driver.findElement(AppiumBy.accessibilityId('$userAlias'));
      await first.click();

      int hasZeroXTZ = await driver.findElements(AppiumBy.xpath(
          '//android.widget.ImageView[contains(@content-desc, "0.0 XTZ")]'
      )).length;
      expect(hasZeroXTZ, 1);

      int hasZeroETH = await driver.findElements(AppiumBy.xpath(
          '//android.widget.ImageView[contains(@content-desc, "0.0 ETH")]'
      )).length;
      expect(hasZeroETH, 1);

      var bitmark = await getElementByContentDesc(driver, 'Bitmark');
      var bitmartDesc = await bitmark.attributes['content-desc'];
      //print(bitmartDesc);
      expect (bitmartDesc.length, 58);

      var ethereum = await getElementByContentDesc(driver, 'Ethereum\n0.0 ETH');
      var ethereumDesc = await ethereum.attributes['content-desc'];
      //print(ethereumDesc);
      expect(ethereumDesc.length, 59);

      var tezos = await getElementByContentDesc(driver, 'Tezos\n0.0 XTZ');
      var tezosDesc = await tezos.attributes['content-desc'];
      //print(tezosDesc);
      expect(tezosDesc.length, 50);

    });

    test("Without Alias", () async {
      await Onboarding.onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");
      int numberAccountBefore = await numberAccount(driver);

      await selectSubSettingMenu(driver, '+ Account');
      var newButton = await getElementByContentDesc(driver, 'New');
      await newButton.click();

      var continueButton = await driver.findElement(continueButtonLocator);
      await continueButton.click();

      var skipButton = await driver.findElement(skipButtonLocator);
      skipButton.click();

      int isContinueWithoutButtonExist =
      await driver.findElements(continueWithouItbuttonLocation).length;
      if (isContinueWithoutButtonExist == 1) {
        var continueWithoutItButton =
        await driver.findElement(continueWithouItbuttonLocation);
        await continueWithoutItButton.click();
      } else {
        continueButton = await driver.findElement(continueButtonLocator);
        await continueButton.click();
      }

      var numberAccountAfter = await numberAccount(driver);
      expect(numberAccountAfter - numberAccountBefore, 1);

    });

  }, timeout: Timeout.none);
}
