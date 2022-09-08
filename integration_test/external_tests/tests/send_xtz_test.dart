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

import 'dart:io';
import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_configurations.dart';
import '../test_data/test_constants.dart';
import '../pages/settings_page.dart';
import '../pages/transactions_page.dart';


void main() async {
  //await dotenv.load();
  late AppiumWebDriver driver;
  final dir = Directory.current;
  group("Deposit Money", () {

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

    // Case 1
    test("send and receive XTZ with API", () async {
      await onBoardingSteps(driver);
      await selectSubSettingMenu(driver, "Settings");

      // import account
      await selectSubSettingMenu(driver, "+ Account");
      await importAnAccountBySeeds(
          driver, "MetaMask", SEED_TO_RESTORE_ACCOUNT, ALIAS_ACCOUNT);

      String address = await getTezosAddress(driver, ALIAS_ACCOUNT);

      // deposit to address
      await depositTezos(address);
      await timeDelay(58);

      // send back
      await gotoTransactionPage(driver, ALIAS_ACCOUNT);
      await sendTezos(driver, XTZ_GETBACK_ADDRESS);
      await timeDelay(20);

      //Assert Back to Transactions Page
      int hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      int hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);
      print("Finish");
    });
    // Case 2
    test("send and receive with 2 account", () async{
      await onBoardingSteps(driver);
      await selectSubSettingMenu(driver, "Settings");

      //Import 2 Accounts"
      await selectSubSettingMenu(driver, "+ Account");
      await importAnAccountBySeeds(
          driver, "MetaMask", SEED_TO_RESTORE_ACCOUNT, ALIAS_ACCOUNT);

      await selectSubSettingMenu(driver, "+ Account");
      await importAnAccountBySeeds(
          driver, "MetaMask", SEED_TO_RESTORE_ANOTHER_ACCOUNT, ALIAS_ANOTHER_ACCOUNT);


      // Get Account addresses
      String address = await getTezosAddress(driver, ALIAS_ACCOUNT);
      String anotherAddress = await getTezosAddress(driver, ALIAS_ANOTHER_ACCOUNT);

      //  Deposit Tezos to address
      await depositTezos(address);
      await timeDelay(58);

      // Send to another address
      await gotoTransactionPage(driver, ALIAS_ACCOUNT);
      await sendTezos(driver, anotherAddress);
      await timeDelay(58);

      // Assert Back to Transactions Page
      int hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      int hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);
      await goBack(driver, 3);


      // Send to GETBACK account
      await gotoTransactionPage(driver, ALIAS_ANOTHER_ACCOUNT);
      await sendTezos(driver, XTZ_GETBACK_ADDRESS);

      //Assert Back to Transactions Page
      hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);
    });

  }, timeout: Timeout.none);
}


