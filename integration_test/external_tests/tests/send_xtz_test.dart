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


const ALIAS_ACCOUNT_A = "ACOUNT_A";
const ALIAS_ACOOUNT_B = "ACOUNT_B";
const ALIAS_DEFAULT = 'Default';

const SEED_TO_RESTORE_ACCOUNT_A =
    "real cat erase wrong shine example pen science barrel shed gentle tilt";
const SEED_TO_RESTORE_ACCOUNT_B =
    "pair copper together wife riot lawn extend rebuild universe brain local easy";

RegExp XTZExp = RegExp(r'[0-9]+.[0-9]*');
RegExp tezosAddressExp = RegExp(r'tz.*');

/*
Future<void> depositTezos(String address) async {
  //final faucetUrl = dotenv.env['TEZOS_FAUCET_URL'] ?? '';
  //final token = dotenv.env['TEZOS_FAUCET_AUTH_TOKEN'] ?? '';
  /*
  await http.post(
    Uri.parse(faucetUrl),
    body: json.encode({"address": address}),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic $token",
    },
  );

   */
}

 */

Future<void> gotoTransactionPage(AppiumWebDriver driver, String alias) async {
  //From Setting Page
  AppiumWebElement toAccount = await driver.findElement(AppiumBy.accessibilityId('$alias'));
  await toAccount.click();
  AppiumBy tezos_XTZLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc,"Tezos (XTZ)")]');
  AppiumWebElement tezos_XTZ = await driver.findElement(tezos_XTZLocator);
  await tezos_XTZ.click();
  AppiumBy transactionsLocator = AppiumBy.accessibilityId('Your transactions will appear here.');
  var hastransactions = await driver.findElements(transactionsLocator).length;
  expect(hastransactions, 1);
}

Future<double> getAccountAmount(AppiumWebDriver driver, String alias) async {

  await gotoTransactionPage(driver, alias);

  var amountXTZ = await driver.findElement(AppiumBy.xpath(
      '//android.view.View[contains(@content-desc,"XTZ")]'));
  String desc = await amountXTZ.attributes['content-desc'];
  print("Decs = $desc");
  String? tmp = await XTZExp.stringMatch(desc);
  print("Tmp = ${tmp as String} )");
  return double.parse(tmp as String);
}

Future<String> getTezosAddress(AppiumWebDriver driver, String alias) async {
  await gotoTransactionPage(driver, alias);
  driver.back();

  AppiumBy tezozAddressLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc,"Tezos tz"]');

  var tezozAddress = await driver.findElement(tezozAddressLocator);
  String decs = await tezozAddress.attributes['content-desc'];
  String? address = tezosAddressExp.stringMatch(decs);
  return address as String;

  return "";
}


void main() {
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

    test("send and receive TXZ", () async {
      print("Start Testing...");
      //print(dotenv.env);
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");

      //Import Account

      //import Account A
      //await importAnAccountBySeeds(
      //    driver, "MetaMask", SEED_TO_RESTORE_ACCOUNT_A, ALIAS_ACCOUNT_A);
      //print("Account A imported");

      //await selectSubSettingMenu(driver, "+ Account");
      // import Account B
      //await importAnAccountBySeeds(
      //    driver, "MetaMask", SEED_TO_RESTORE_ACCOUNT_B, ALIAS_ACOOUNT_B);

      double amountA = await getAccountAmount(driver, ALIAS_DEFAULT);
      driver.back();
      double amountB = 1.0;await getAccountAmount(driver, ALIAS_ACOOUNT_B);

      print("amountA = $amountA // amountB = $amountB");

      /*
      AppiumBy defaultLocator = AppiumBy.xpath(''
          '//android.view.View[@content-desc="Default"]');
      var defaultBtn =  await driver.findElement(defaultLocator);

      // TODO
      // Expect Text Account
      defaultBtn.click();


      /*
      final xtzWallet = await (await injector<CloudDatabase>()
          .personaDao
          .getDefaultPersonas())
          .first
          .wallet()
          .getTezosWallet();

       */

      //await depositTezos(xtzWallet.address);

      AppiumBy tezos_XTZLocator = AppiumBy.xpath(
          '//android.widget.ImageView[contains(@content-desc, "Tezos (XTZ)")]');
      var tezos_XTZ = await driver.findElement(tezos_XTZLocator);
      tezos_XTZ.click();

      // CHeck if has Your Transaction Here
      AppiumBy transactionsLocator = AppiumBy.accessibilityId('Your transactions will appear here.');
      var hastransactions = await driver.findElements(transactionsLocator).length;
      expect(hastransactions, 1);

      AppiumBy sendLocator = AppiumBy.accessibilityId('SEND');
      AppiumWebElement sendButton = await driver.findElement(sendLocator);
      sendButton.click();

      //TODO OK

      print(XTZ_GETBACK_ADDRESS);
      AppiumBy toAddressLocator = AppiumBy.xpath('/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View[2]/android.widget.EditText[1]');
      AppiumWebElement toAddress = await driver.findElement(toAddressLocator);
      await toAddress.click();
      await toAddress.sendKeys(XTZ_GETBACK_ADDRESS);
      await driver.keyboard.sendKeys('\n');
      print("Paste OK");
      // TODO
      // Send Account

      AppiumBy reviewButtonLocator = AppiumBy.accessibilityId("REVIEW");
      var reviewButton = await driver.findElement(reviewButtonLocator);
      var isClickable = await reviewButton.attributes['clickable'];
      expect(isClickable, 'false');

      AppiumBy estimationFailLocator = AppiumBy.accessibilityId('Estimation failed');
      var hasEstimationFail = await driver.findElements(estimationFailLocator).length;
      expect(hasEstimationFail, 1);


      AppiumBy centerScreenLocator = AppiumBy.xpath(
          '/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View[2]');

      var centerScreen = await driver.findElement(centerScreenLocator);
      await centerScreen.click();
      print("Center Clicked");

      AppiumBy maxLocator = AppiumBy.xpath(
          '//android.view.View[contains(@content-desc,"Max")]');
      var maxXTZText = await driver.findElement(maxLocator);
      RegExp XTZExp = RegExp(r'[0-9]+.[0-9]*');
      var maxXTZStr = await XTZExp
      double nowXTZ = double.parse(maxXTZStr as String);
      double sendXTZ = nowXTZ;
      double restXTZ = nowXTZ - sendXTZ;

      AppiumBy XTZSendTextLocator = AppiumBy.xpath(
          '/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View[2]/android.widget.EditText[2]'
      );

      var XTZSendText = await driver.findElement(XTZSendTextLocator);
      XTZSendText.sendKeys(sendXTZ.toString());
      driver.keyboard.sendKeys('\n');

      reviewButton = await driver.findElement(reviewButtonLocator);
      isClickable = await reviewButton.attributes['clickable'];
      //expect(isClickable, 'true');

      driver.back();

      var hasXTZ = await driver.findElements(AppiumBy.accessibilityId('$restXTZ XTZ')).length;
      expect(hasXTZ, 1);
      print("End");


       */










    });
    /*
    test("EULA", () async {
      // Open App at Home Page
      await onBoardingSteps(driver);

      // GO to Settings Page
      await selectSubSettingMenu(driver, "Settings");

      // Scroll Down
      await scrollSettingPage(driver);

      await selectSubSettingMenu(driver, "EULA");

      int hasLicense = await driver.findElements(AppiumBy.xpath(
          "//android.view.View[@content-desc='Autonomy End User License Agreement']"
      )).length;

      expect(hasLicense, 1);

      await driver.back();

      var hasEULA = await driver.findElements(
          AppiumBy.accessibilityId("EULA")).length;
      expect(hasEULA, 1);
    });

     */
    /*
    test("Privacy Policy", () async {
      await onBoardingSteps(driver);

      await selectSubSettingMenu(driver, "Settings");

      await scrollSettingPage(driver);

      await selectSubSettingMenu(driver, "Privacy Policy");

      int hasPrivacyPolicy = await driver.findElements(AppiumBy.xpath(
          "//android.view.View[@content-desc='Autonomy Privacy Policy']"
      )).length;

      expect(hasPrivacyPolicy, 1);

      await driver.back();

      var hasPrivacyAndPolicy = await driver.findElements(
          AppiumBy.accessibilityId("Privacy Policy")).length;
      expect(hasPrivacyAndPolicy, 1);
    });

     */


  }, timeout: Timeout.none);
}


