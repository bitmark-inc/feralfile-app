//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

//import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      await driver.app.remove(AUTONOMY_APPPACKAGE);
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
      double balance = await getTezosBalance(driver, ALIAS_ACCOUNT);

      // deposit to address
      var depositTime = await depositTezos(address);
      await timeDelay(40);
      //var depositTime = DateTime.parse('2022-09-15 08:57');

      double balanceAfterDeposit = await getTezosBalance(driver, ALIAS_ACCOUNT);
      expect((balance + DEPOSIT_AMOUNT - balanceAfterDeposit).abs() <= EPS, true);

      await gotoTransactionPage(driver, ALIAS_ACCOUNT);
      AppiumWebElement receiveTransaction = await getRecentTransaction(driver, "Received");
      await receiveTransaction.click();
      await expectReceiveTransaction(driver, XTZ_GETBACK_ADDRESS, from24to12(depositTime), DEPOSIT_AMOUNT);
      await goBack(driver, 1);

      // send back
      var lst = await sendTezos(driver, XTZ_GETBACK_ADDRESS);
      double fee = lst[0] as double;
      DateTime sendTime = lst[1] as DateTime;
      double sendAmount = lst[2] as double;
      double total = await round(sendAmount + fee, 5);
      await timeDelay(40);

      //Assert Back to Transactions Page
      int hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      int hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);

      await goBack(driver, 3);
      double balanceAfterSendBack = await getTezosBalance(driver, ALIAS_ACCOUNT);
      //print('($balanceAfterDeposit - $total - $balanceAfterSendBack) = ${balanceAfterDeposit - total - balanceAfterSendBack}');
      expect((balanceAfterDeposit - total - balanceAfterSendBack).abs() < EPS, true);

      await gotoTransactionPage(driver, ALIAS_ACCOUNT);
      // Get Latest Transaction
      AppiumWebElement sentTransaction = await getRecentTransaction(driver);
      var sentDesc = await sentTransaction.attributes['content-desc'];
      double minustotal = await getTezosFromString(sentDesc);
      expect((minustotal + total).abs() <= EPS, true);
      await sentTransaction.click();
      await expectSentTransaction(driver, XTZ_GETBACK_ADDRESS, from24to12(sendTime), sendAmount, fee);
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
      String addressA = await getTezosAddress(driver, ALIAS_ACCOUNT);
      String addressB = await getTezosAddress(driver, ALIAS_ANOTHER_ACCOUNT);

      double balanceA = await getTezosBalance(driver, ALIAS_ACCOUNT);
      double balanceB = await getTezosBalance(driver, ALIAS_ANOTHER_ACCOUNT);

      //  Deposit Tezos to address
      DateTime depositTime = await depositTezos(addressA);
      await timeDelay(30);

      // Check Balance After Deposit
      double balanceAAfterDeposit = await getTezosBalance(driver, ALIAS_ACCOUNT);
      expect((balanceA + DEPOSIT_AMOUNT - balanceAAfterDeposit).abs() < EPS, true);
      
      // Send to another address
      await gotoTransactionPage(driver, ALIAS_ACCOUNT);
      var lst = await sendTezos(driver, addressB);
      await timeDelay(40);
      DateTime sentToBTime = lst[1] as DateTime;
      double sentToBFee = lst[0] as double;
      double amountSentToB = lst[2] as double;
      double totalSentToB = await round(amountSentToB + sentToBFee, 5);

      // Assert Back to Transactions Page
      int hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      int hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);

      AppiumWebElement sentFromA = await getRecentTransaction(driver, 'Sent');
      await sentFromA.click();
      await expectSentTransaction(driver, addressB, from24to12(sentToBTime), amountSentToB, sentToBFee);
      await goBack(driver, 4);

      // Send to GETBACK account
      await gotoTransactionPage(driver, ALIAS_ANOTHER_ACCOUNT);
      // Check balance
      AppiumWebElement receivedFromA = await getRecentTransaction(driver, 'Received');
      await receivedFromA.click();
      await expectReceiveTransaction(driver, addressA, from24to12(sentToBTime), amountSentToB);
      await goBack(driver, 4);

      await gotoTransactionPage(driver, ALIAS_ANOTHER_ACCOUNT);

      var lst2 = await sendTezos(driver, XTZ_GETBACK_ADDRESS);
      await timeDelay(40);

      DateTime sendFromBTime = lst2[1] as DateTime;
      double sendFromBFee = lst2[0] as double;
      double fromBAmount = lst2[2] as double;

      //Assert Back to Transactions Page
      hasSendButton = await driver.findElements(AppiumBy.accessibilityId("SEND")).length;
      expect(hasSendButton, 1);
      hasReceiveButton = await driver.findElements(AppiumBy.accessibilityId('RECEIVE')).length;
      expect(hasReceiveButton, 1);

      await goBack(driver, 3);

      double balanceAAtEnd = await getTezosBalance(driver, ALIAS_ACCOUNT);
      double balanceBAtEnd = await getTezosBalance(driver, ALIAS_ANOTHER_ACCOUNT);
      //print("($balanceA + $DEPOSIT_AMOUNT - $totalSentToB - $balanceAAtEnd) = ${(balanceA + DEPOSIT_AMOUNT - totalSentToB - balanceAAtEnd)}");
      expect((balanceA + DEPOSIT_AMOUNT - totalSentToB - balanceAAtEnd).abs() <= EPS, true);
      //print("($balanceB + $amountSentToB - $fromBAmount - $sendFromBFee - $balanceBAtEnd) = ${(balanceB + amountSentToB - fromBAmount - sendFromBFee - balanceBAtEnd)}");
      expect((balanceB + amountSentToB - fromBAmount -sendFromBFee - balanceBAtEnd).abs() <= EPS, true);

      await gotoTransactionPage(driver, ALIAS_ANOTHER_ACCOUNT);

      var fromB = await getRecentTransaction(driver);
      await fromB.click();
      await expectSentTransaction(driver, XTZ_GETBACK_ADDRESS, from24to12(sendFromBTime), fromBAmount, sendFromBFee);
    });

  }, timeout: Timeout.none);
}


