//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

//import 'package:flutter_dotenv/flutter_dotenv.dart';

//import 'package:autonomy_flutter/common/injector.dart';
//import 'package:autonomy_flutter/database/cloud_database.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';


/*
  From: Transactions Page
  To: Transaction Page
 */
Future<void> sendTezos(AppiumWebDriver driver, String address) async {

  AppiumBy sendLocator = AppiumBy.accessibilityId('SEND');
  AppiumWebElement sendButton = await driver.findElement(sendLocator);
  sendButton.click();

  AppiumBy toAddressLocator = AppiumBy.xpath(
      '/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View[2]/android.widget.EditText[1]'
  );
  AppiumWebElement toAddress = await driver.findElement(toAddressLocator);
  await toAddress.click();
  await toAddress.sendKeys(address);
  await driver.keyboard.sendKeys('\n');

  AppiumBy reviewButtonLocator = AppiumBy.accessibilityId("REVIEW");
  var reviewButton = await driver.findElement(reviewButtonLocator);
  var isClickable = await reviewButton.attributes['clickable'];
  expect(isClickable, 'false'); // Review is unClickable

  AppiumWebElement maxButton = await getElementByContentDesc(driver, 'Max');
  await maxButton.click();

  // Click on Review Button
  reviewButton = await driver.findElement(reviewButtonLocator);
  isClickable = await reviewButton.attributes['clickable'];
  expect(isClickable, 'true');
  await reviewButton.click();

  sendButton = await driver.findElement(sendLocator);
  await sendButton.click();
  print("Send Button Clicked");
}