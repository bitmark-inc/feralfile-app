//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/expect.dart';

import '../commons/test_util.dart';

AppiumBy addLinkLocator = const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'I already have NFTs in other wallets')]");
AppiumBy metaMaskButtonLocator = const AppiumBy.accessibilityId("MetaMask");
AppiumBy linkAccountLinkLocator = const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'View your NFTs without Autonomy accessing your private keys in MetaMask.')]");

AppiumBy importAccountLinkLocator = const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'Import')]");

AppiumBy mobileLinkLocator =
    const AppiumBy.accessibilityId("Mobile app on this device");
AppiumBy metaMaskApproveButtonLocator = const AppiumBy.xpath(
    "//android.view.ViewGroup[contains(@resource-id,'connect-approve-button')]");
AppiumBy accountLinkedHeaderLocator =
    const AppiumBy.accessibilityId("Account linked");
AppiumBy skipButtonLocator = const AppiumBy.accessibilityId("SKIP");
AppiumBy alreadyLinkedHeaderLocator =
    const AppiumBy.accessibilityId("Already linked");

Future<void> addExistingMetaMaskAccount(
    AppiumWebDriver driver, String type, String metaMaskAlias) async {
  var addLink = await driver.findElement(addLinkLocator);
  await addLink.click();
  // sleep(Duration(seconds: 1));
  var metaMaskButton = await driver.findElement(metaMaskButtonLocator);
  await metaMaskButton.click();

  var linkAccountLink = await driver.findElement(linkAccountLinkLocator);
  await linkAccountLink.click();

  if (type == "app") {
    var mobileLink = await driver.findElement(mobileLinkLocator);
    await mobileLink.click();

    var metaMaskApproveButton =
        await driver.findElement(metaMaskApproveButtonLocator);
    metaMaskApproveButton.click();
  } else {
    // This for block code we will handle link metamask account by web browser
  }

  var accountLinked =
      await driver.findElements(accountLinkedHeaderLocator).length;
  expect(accountLinked, 1);

  sleep(const Duration(seconds: 5));
  if (metaMaskAlias.isNotEmpty) {
    await enterAccountAlias(driver, metaMaskAlias);
  } else {
    var skipButton = await driver.findElement(skipButtonLocator);
    await skipButton.click();
  }
}

Future<void> importAnAccountBySeeds(AppiumWebDriver driver, String accountType,
    String seeds, String alias) async {
  var addLink = await driver.findElement(addLinkLocator);
  await addLink.click();
  // sleep(Duration(seconds: 1));
  var accountTypeButton =
      await driver.findElement(AppiumBy.accessibilityId("$accountType"));
  await accountTypeButton.click();

  var importAccountLink = await driver.findElement(importAccountLinkLocator);
  await importAccountLink.click();

  await enterSeeds(driver, seeds);

  await enterAccountAlias(driver, alias);

  await continueStep(driver);
}

Future<int> numberAccount(AppiumWebDriver driver) async {
  var scrollView = await driver.findElements(AppiumBy.className('android.widget.ScrollView')).first;
  //xpath('/hierarchy/android.widget.FrameLayout/android.widget.LinearLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ScrollView'));
  int count = 0;
  bool isContinue = true;

  var lst = await scrollView.findElements(
      AppiumBy.className('android.view.View'));
  var a = await lst.toList();

  await Future.forEach(a, (AppiumWebElement element) async {
    var decs = await element.attributes['content-desc'];
    if (decs == 'Preferences') {
      isContinue = false;
    }
    if (isContinue) {
      count += 1;
    }
  });

  return count;
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

RegExp XTZExp = RegExp(r'[0-9]+.[0-9]*');
Future<double> getTezosBalance(AppiumWebDriver driver, String alias) async {

  AppiumWebElement toAccount = await driver.findElement(AppiumBy.accessibilityId('$alias'));
  await toAccount.click();
  await timeDelay(3); // wait for loading

  AppiumBy tezozAddressLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "Tezos")][not(contains(@content-desc, "--"))]');

  var tezozAddress = await driver.findElements(tezozAddressLocator).first;
  String decs = await tezozAddress.attributes['content-desc'];
  String? address = XTZExp.stringMatch(decs);
  double balance = double.parse(address as String ?? '0.0');
  await goBack(driver, 1);
  return balance;
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