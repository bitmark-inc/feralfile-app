//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../pages/onboarding_page.dart';
import '../test_data/test_configurations.dart';


var supportLocator = AppiumBy.xpath(
    '//android.widget.ImageView[@content-desc="Settings"]/../android.widget.ImageView[2]');

Future<void> testSupportSubMenu(AppiumWebDriver driver, String menu) async {
  var supportButton = await driver.findElements(supportLocator).first;
  await supportButton.click();
  int hasFeature = await driver.findElements(AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "$menu")]')).length;
  expect(hasFeature, 1);
}