//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:appium_driver/async_io.dart';
import 'package:http/http.dart' as http;


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

Future<void> depositTezos(String address) async {
  final faucetUrl = dotenv.env['TEZOS_FAUCET_URL'] ?? '';
  final token = dotenv.env['TEZOS_FAUCET_AUTH_TOKEN'] ?? '';

  //final faucetUrl = TEZOS_FAUCET_URL;
  //final token = TEZOS_FAUCET_AUTH_TOKEN;

  await http.post(
    Uri.parse(faucetUrl),
    body: json.encode({"address": address}),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic $token",
    },
  );
}

Future<AppiumWebElement> getElementByContentDesc(AppiumWebDriver driver, String contain) async {
  AppiumBy locator = AppiumBy.xpath(
      '//*[contains(@content-desc,"$contain")]');
  var element = driver.findElements(locator).elementAt(0);
  return element;
}

Future<void> goBack(AppiumWebDriver driver, int step) async {
  for (int i = 0; i < step; i++) {
    await driver.back();
  }
}

Future<void> gotoTransactionPage(AppiumWebDriver driver, String alias) async {
  //From Setting Page
  AppiumWebElement toAccount = await driver.findElement(AppiumBy.accessibilityId('$alias'));
  await toAccount.click();

  AppiumBy tezos_XTZLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc,"Tezos")]');
  AppiumWebElement tezos_XTZ = await driver.findElements(tezos_XTZLocator).first;
  await tezos_XTZ.click();

  AppiumBy historyButtonLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "History")]');
  var historyButton = await driver.findElement(historyButtonLocator);
  historyButton.click();
}

RegExp TEZOS_ADRESS_EXP = RegExp(r'tz.*');
Future<String> getTezosAddress(AppiumWebDriver driver, String alias) async {
  await timeDelay(1);
  AppiumWebElement toAccount = await driver.findElement(AppiumBy.accessibilityId('$alias'));
  await toAccount.click();

  AppiumBy tezozAddressLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "Tezos")]');

  var tezozAddress = await driver.findElements(tezozAddressLocator).first;
  String decs = await tezozAddress.attributes['content-desc'];
  String? address = TEZOS_ADRESS_EXP.stringMatch(decs);

  await goBack(driver, 1);
  return address as String;
}

Future<void> timeDelay(int second) async {
  Duration dur = Duration(seconds: 1);
  for (int i = 0; i < second; i++){
    await Future.delayed(dur);
  }
}

