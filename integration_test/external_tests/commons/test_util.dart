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

Future<bool> findArtwork(AppiumWebDriver driver, String artworkName) async {
  int i = 2;
  int hasArtwork = await driver
      .findElements(AppiumBy.xpath(
          "//android.widget.ScrollView/android.widget.ImageView[$i]"))
      .length;

  while (hasArtwork == 1) {
    sleep(const Duration(seconds: 2));
    var artworkIcon = await driver.findElement(AppiumBy.xpath(
        "//android.widget.ScrollView/android.widget.ImageView[$i]"));
    await artworkIcon.click();
    i++;
    int isCorrectArtwork = await driver
        .findElements(AppiumBy.xpath(
            "//android.widget.ImageView[contains(@content-desc,'$artworkName')]"))
        .length;

    if (isCorrectArtwork == 1) {
      return true;
    } else {
      var closeArtworkButton =
          await driver.findElement(closeArtworkButtonLocator);
      await closeArtworkButton.click();
    }
  }
  return false;
}

Future<void> sendAwrtwork(AppiumWebDriver driver, String artworkName,
    String toAddress, int amount) async {
  bool isArtworkFound = await findArtwork(driver, artworkName);

  var artworkTitle = await driver.findElement(AppiumBy.xpath(
      "//android.widget.ImageView[contains(@content-desc,'$artworkName')]"));
  await artworkTitle.click();

  var dotIcon = await driver.findElement(dotIconLocator);
  await dotIcon.click();
  var sendArtworkButton = await driver.findElement(sendArtworkButtonLocator);
  await sendArtworkButton.click();

  var reviewButton = await driver.findElement(reviewButtonLocator);
  String statusReviewButton = await reviewButton.attributes["clickable"];

  expect(statusReviewButton, "false");

  var quantityTxt = await driver.findElement(quantityTxtLocator);
  await quantityTxt.click();
  await quantityTxt.clear();
  await Future.delayed(const Duration(seconds: 1));
  await quantityTxt.sendKeys(amount.toString());

  var toTxt = await driver.findElement(toTxtLocator);
  await toTxt.click();
  await toTxt.sendKeys(toAddress);

  await driver.device.pressKeycode(66);

  await Future.delayed(const Duration(seconds: 5));
  int isFeeCalculated =
      await driver.findElements(isFeeCalculatedLocator).length;

  expect(isFeeCalculated, 1);

  var reviewButton1 = await driver.findElement(reviewButtonLocator);
  statusReviewButton = await reviewButton1.attributes["clickable"];
  expect(statusReviewButton, "true");

  await reviewButton1.click();

  var sendButton = await driver.findElement(sendButtonLocator);
  await sendButton.click();
}

Future<void> wait4TezBlockchainConfirmation(AppiumWebDriver driver) async {
  await Future.delayed(const Duration(seconds: 40));
  await driver.device.getDisplayDensity();
  await Future.delayed(const Duration(seconds: 40));
  await driver.device.getDisplayDensity();
  await Future.delayed(const Duration(seconds: 30));
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
