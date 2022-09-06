//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';
import 'dart:math';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';
import 'package:intl/intl.dart';

import 'dart:convert';

AppiumBy settingButtonLocator = const AppiumBy.accessibilityId("Settings");
AppiumBy accountAliasLocator =
    const AppiumBy.xpath("//android.widget.EditText[@text='Enter alias']");
AppiumBy saveAliasButtonLocator = const AppiumBy.accessibilityId("SAVE ALIAS");
AppiumBy continueButtonLocator = const AppiumBy.accessibilityId("CONTINUE");
AppiumBy accountSeedsLocator = const AppiumBy.xpath(
    "//android.widget.EditText[contains(@text,'Enter recovery phrase')]");

AppiumBy confirmButtonLocator = const AppiumBy.accessibilityId("CONFIRM");
AppiumBy closeArtworkButtonLocator =
    const AppiumBy.accessibilityId("CloseArtwork");

AppiumBy dotIconLocator = const AppiumBy.accessibilityId("AppbarAction");
AppiumBy sendArtworkButtonLocator =
    const AppiumBy.xpath("//android.view.View[@content-desc='Send artwork']");
AppiumBy reviewButtonLocator = const AppiumBy.accessibilityId("REVIEW");
AppiumBy quantityTxtLocator =
    const AppiumBy.xpath("//android.widget.EditText[@text='1']");
AppiumBy toTxtLocator = const AppiumBy.xpath(
    "//android.widget.EditText[@text='Paste or scan address']");
AppiumBy isFeeCalculatingLocator = const AppiumBy.xpath(
    "//android.view.View[contains(@content-desc,'Gas fee: calculating')]");
AppiumBy isFeeCalculatedLocator = const AppiumBy.xpath(
    "//android.view.View[contains(@content-desc,'Gas fee: 0.')]");
AppiumBy sendButtonLocator = const AppiumBy.accessibilityId("SEND");

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

Future<void> scrollSettingPage(driver) async {
  var scrollUIAutomator = await 'new UiScrollable(new UiSelector().className("android.widget.ScrollView")).scrollForward()';
  await scroll(driver, scrollUIAutomator);
  scrollUIAutomator = await 'new UiScrollable(new UiSelector().className("android.widget.ScrollView")).scrollToEnd(10)';
  await scroll(driver, scrollUIAutomator);
}

Future<void> captureScreen(AppiumWebDriver driver) async {
  var screenshot = await driver.captureScreenshotAsBase64();

  final decodedBytes = base64Decode(screenshot.replaceAll(RegExp(r'\s+'), ''));

  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('MMddyyyy');
  final String formattedFolder = formatter.format(now);

  final filename = DateTime.now().microsecondsSinceEpoch;
  var file = await File("/tmp/AUResult/$formattedFolder/$filename.png")
      .create(recursive: true);
  file.writeAsBytesSync(decodedBytes);
}
