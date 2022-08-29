//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';

AppiumBy startButtonLocator = const AppiumBy.accessibilityId("START");
AppiumBy continueButtonLocator = const AppiumBy.accessibilityId("CONTINUE");
AppiumBy noLinkLocator = const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'Make a new account with addresses you can use')]");

AppiumBy skipButtonLocator = const AppiumBy.accessibilityId("SKIP");
AppiumBy notNowButtonLocator = const AppiumBy.accessibilityId("NOT NOW");

AppiumBy continueWithouItbuttonLocation = const AppiumBy.xpath(
    "//android.widget.Button[@content-desc='CONTINUE WITHOUT IT']");
AppiumBy restoreButtonLocator = const AppiumBy.accessibilityId("RESTORE");

Future<void> onBoardingSteps(AppiumWebDriver driver) async {
  int isStartButtonExist = await driver.findElements(startButtonLocator).length;
  if (isStartButtonExist == 1) {
    var startButton = await driver.findElement(startButtonLocator);
    await startButton.click();

    var continueButton = await driver.findElement(continueButtonLocator);
    await continueButton.click();

    var noLink = await driver.findElement(noLinkLocator);
    await noLink.click();

    continueButton = await driver.findElement(continueButtonLocator);
    await continueButton.click();

    var skipButton = await driver.findElement(skipButtonLocator);
    await skipButton.click();

    sleep(const Duration(seconds: 2));
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
  } else {
    var restoreButton = await driver.findElement(restoreButtonLocator);
    await restoreButton.click();
  }

  var notNowButton = await driver.findElement(notNowButtonLocator);
  await notNowButton.click();

  //Servey is no longer displays in app, so this code block should be commented
  /* bool isServeyEmpty = await driver
      .findElements(AppiumBy.xpath(
          "//android.view.View[contains(@content-desc,'Take a one-question survey')]"))
      .isEmpty;
  if (isServeyEmpty == false) {
    var surveyOverlay = await driver.findElement(AppiumBy.xpath(
        "//android.view.View[contains(@content-desc,'Take a one-question survey')]"));
    surveyOverlay.click();

    var wordOfMouthOption =
        await driver.findElement(AppiumBy.accessibilityId("Word of mouth"));
    wordOfMouthOption.click();

    continueButton =
        await driver.findElement(AppiumBy.accessibilityId("CONTINUE"));
    await continueButton.click();

    continueButton =
        await driver.findElement(AppiumBy.accessibilityId("CONTINUE"));
    await continueButton.click();
  } */
}
