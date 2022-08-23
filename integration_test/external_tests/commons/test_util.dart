//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:appium_driver/async_io.dart';

AppiumBy settingButtonLocator = AppiumBy.accessibilityId("Settings");
AppiumBy accountAliasLocator = AppiumBy.xpath(
    "//android.widget.FrameLayout[@resource-id='android:id/content']//android.widget.EditText");
AppiumBy saveAliasButtonLocator = AppiumBy.accessibilityId("SAVE ALIAS");

Future<void> selectSubSettingMenu(AppiumWebDriver driver, String menu) async {
  String sub_menu = await menu;
  while (menu.indexOf('->') > 0) {
    int index = await menu.indexOf('->');
    sub_menu = await menu.substring(0, index);
    menu = await menu.substring(menu.indexOf('->') + 2, menu.length);

    if (sub_menu == "Settings") {
      var settingButton = await driver.findElement(settingButtonLocator);
      settingButton.click();
    } else {
      var subButton =
          await driver.findElement(AppiumBy.accessibilityId(sub_menu));
      subButton.click();
    }
  }
  var lastButton = await driver.findElement(AppiumBy.accessibilityId(menu));
  lastButton.click();
}

Future<String> genTestDataRandom(String baseString) async {
  var rng = Random();
  baseString = baseString + rng.nextInt(10000).toString();
  return baseString;
}

Future<void> typeAccountAlias(AppiumWebDriver driver, String alias) async {
  var accountAliasTxt = await driver.findElement(accountAliasLocator);
  await accountAliasTxt.click();
  await accountAliasTxt.sendKeys(alias);

  var saveAliasButton = await driver.findElement(saveAliasButtonLocator);
  saveAliasButton.click();
}
