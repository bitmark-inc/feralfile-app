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

AppiumBy newAccountLocator =  const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'Make a new account with addresses you can use')]");

AppiumBy continueButtonLocator = const AppiumBy.accessibilityId('CONTINUE WITHOUT IT');
AppiumBy saveAliasLocator = const AppiumBy.accessibilityId('SAVE ALIAS');
AppiumBy enterAliasLocator = const AppiumBy.className('android.widget.EditText');

Future<AppiumWebElement> getElementByContentDesc(AppiumWebDriver driver, String contain) async {
  AppiumBy locator = AppiumBy.xpath(
      '//*[contains(@content-desc,"$contain")]');
  var element = driver.findElements(locator).elementAt(0);
  return element;
}

Future<void> timeDelay(int second) async {
  Duration dur = Duration(seconds: 1);
  for (int i = 0; i < second; i++){
    print(i);
    await Future.delayed(dur);
  }
}

Future<int> numberAccount(AppiumWebDriver driver) async {
  var scrollView = await driver.findElements(AppiumBy.className('android.widget.ScrollView')).first;
      //xpath('/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ScrollView'));
  int count = 0;
  bool isContinue = true;

  var lst = await scrollView.findElements(
      AppiumBy.className('android.view.View'));
  var a = await lst.toList();

  await Future.forEach(a, (AppiumWebElement element) async {
    var decs = await element.attributes['content-desc'];
    if (decs == 'Preferences') {
      isContinue = false;
    }
    if (isContinue) {
      count += 1;
    }
  });


  return count;
}

void main() {
  late AppiumWebDriver driver;
  final dir = Directory.current;
  group("Create new account", () {

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
      await selectSubSettingMenu(driver, "Settings->+ Account");

      var newButton = await getElementByContentDesc(driver, 'New');
      await newButton.click();

      var continueButton = await driver.findElement(AppiumBy.accessibilityId('CONTINUE'));
      await continueButton.click();

      String userAlias = 'Alias';

      AppiumBy enterAliasLocator = AppiumBy.className('android.widget.EditText');
      var enterAlias = await driver.findElement(enterAliasLocator);
      await enterAlias.click();
      await enterAlias.sendKeys(userAlias);
      await driver.keyboard.sendKeys('\n');

      var saveButton = await getElementByContentDesc(driver, 'SAVE ALIAS');
      await saveButton.click();

      var continueWithout = await driver.findElement(
          AppiumBy.accessibilityId('CONTINUE WITHOUT IT'));
      await continueWithout.click();

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
    });

    test("Without Alias", () async {
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");
      int numberAccountBefore = await numberAccount(driver);

      await selectSubSettingMenu(driver, '+ Account');
      var newButton = await getElementByContentDesc(driver, 'New');
      await newButton.click();

      var continueButton = await driver.findElement(AppiumBy.accessibilityId('CONTINUE'));
      await continueButton.click();

      var skipButton = await driver.findElement(AppiumBy.accessibilityId('SKIP'));
      skipButton.click();

      var continueWithout = await driver.findElement(
          AppiumBy.accessibilityId('CONTINUE WITHOUT IT'));
      await continueWithout.click();
      var numberAccountAfter = await numberAccount(driver);
      expect(numberAccountAfter - numberAccountBefore, 1);

    });

  }, timeout: Timeout.none);
}
