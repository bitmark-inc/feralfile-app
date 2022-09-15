//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:appium_driver/async_io.dart';

AppiumBy settingButtonLocator = const AppiumBy.accessibilityId("Settings");
AppiumBy accountAliasLocator =
    const AppiumBy.xpath("//android.widget.EditText[@text='Enter alias']");
AppiumBy saveAliasButtonLocator = const AppiumBy.accessibilityId("SAVE ALIAS");
AppiumBy continueButtonLocator = const AppiumBy.accessibilityId("CONTINUE");
AppiumBy accountSeedsLocator = const AppiumBy.xpath(
    "//android.widget.EditText[contains(@text,'Enter recovery phrase')]");

AppiumBy confirmButtonLocator = const AppiumBy.accessibilityId("CONFIRM");

Future<void> selectSubSettingMenu(AppiumWebDriver driver, String menu) async {
  String sub_menu = await menu;
  while (menu.indexOf('->') > 0) {
    int index = await menu.indexOf('->');
    sub_menu = await menu.substring(0, index);
    menu = await menu.substring(menu.indexOf('->') + 2, menu.length);

    if (sub_menu == "Settings") {
      var settingButton = await driver.findElement(settingButtonLocator);
      await settingButton.click();
    } else {
      var subButton =
          await driver.findElement(AppiumBy.accessibilityId(sub_menu));
      await subButton.click();
    }
  }
  var lastButton = await driver.findElement(AppiumBy.accessibilityId(menu));
  await lastButton.click();
}

Future<String> genTestDataRandom(String baseString) async {
  var rng = Random();
  baseString = baseString + rng.nextInt(10000).toString();
  return baseString;
}

Future<void> enterAccountAlias(AppiumWebDriver driver, String alias) async {
  var accountAliasTxt = await driver.findElement(accountAliasLocator);
  await accountAliasTxt.click();
  await accountAliasTxt.sendKeys(alias);

  var saveAliasButton = await driver.findElement(saveAliasButtonLocator);
  await saveAliasButton.click();
}

Future<void> enterSeeds(AppiumWebDriver driver, String seeds) async {
  var accountSeedsTxt = await driver.findElement(accountSeedsLocator);
  await accountSeedsTxt.click();
  await accountSeedsTxt.sendKeys(seeds);

  var confirmButton = await driver.findElement(confirmButtonLocator);
  await confirmButton.click();
}


Future<void> scroll(driver, scrollUIAutomator) async {
  var finder = await AppiumBy.uiautomator(scrollUIAutomator);
  await driver.findElement(finder);
}

Future<void> scrollUntil(AppiumWebDriver driver, String decs) async {
  var subSelector = 'new UiSelector().descriptionContains("$decs")';
  var scrollViewSeletor = 'new UiSelector().className("android.widget.ScrollView")';
  var scrollUIAutomator = await 'new UiScrollable($scrollViewSeletor).setSwipeDeadZonePercentage(0.4).scrollIntoView($subSelector)';
  await scroll(driver, scrollUIAutomator);
}

Future<void> timeDelay(int second) async {
  Duration dur = Duration(seconds: 1);
  for (int i = 0; i < second; i++){
    print(i);
    await Future.delayed(dur);
  }
}

Future<void> goBack(AppiumWebDriver driver, int step) async {
  for (int i = 0; i < step; i++) {
    await driver.back();
  }
}
