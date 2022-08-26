//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';

AppiumBy startButtonLocator = AppiumBy.accessibilityId("START");
AppiumBy continueButtonLocator = AppiumBy.accessibilityId("CONTINUE");
AppiumBy noLinkLocator = AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'Make a new account with addresses you can use')]");

AppiumBy skipButtonLocator = AppiumBy.accessibilityId("SKIP");
AppiumBy notNowButtonLocator = AppiumBy.accessibilityId("NOT NOW");

AppiumBy continueWithouItbuttonLocation = AppiumBy.xpath(
    "//android.widget.Button[@content-desc='CONTINUE WITHOUT IT']");

Future<void> onBoardingSteps(AppiumWebDriver driver) async {
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

  sleep(Duration(seconds: 2));
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
