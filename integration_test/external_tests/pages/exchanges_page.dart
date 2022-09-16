//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';

import '../test_data/test_configurations.dart';

AppiumBy objktHamburgerIconLocator =
    const AppiumBy.xpath("//app-info-popover//a[@class='burger-menu']");
AppiumBy objktSyncButtonLocator = const AppiumBy.xpath(
    "//div[@class='header-mobile-menu-popover']//a[@class='sync']");
AppiumBy fxhashHamburgerIconLocator = const AppiumBy.xpath(
    "//header//button[contains(@class,'Navigation_hamburger')]");
AppiumBy fxhashSyncButtonLocator = const AppiumBy.xpath(
    "//header//div[contains(@class,'Navigation_content')]//button[.='sync']");
AppiumBy connectButtonLocator = const AppiumBy.accessibilityId("CONNECT");
AppiumBy signButtonLocator = const AppiumBy.accessibilityId("SIGN");
AppiumBy teiaSyncButtonLocator =
    const AppiumBy.xpath("//header//button/div[.='Sync']");
AppiumBy versumSyncButtonLocator = const AppiumBy.xpath(
    "//div[contains(@class,'vertical-true')]/button[.='Log in']");
AppiumBy akaswapSyncButtonLocator =
    const AppiumBy.xpath("//button[./div[.='Connect Wallet']]");
AppiumBy typedartSyncButtonLocator = const AppiumBy.xpath("//button[.='sync']");
AppiumBy hicetnuncSyncButtonLocator =
    const AppiumBy.xpath("//button[./div[.='sync']]");

AppiumBy FFsigninLocator = AppiumBy.xpath(
    "//div[contains(@class, 'content-center')]/p[.='Sign In']");
AppiumBy FFconnectYourWalletLocator = AppiumBy.xpath(
    "//div[contains(@class, 'option')][1]/p[contains(., 'Connect')]");
AppiumBy FFtezosWalletLocator = AppiumBy.xpath(
    "//div[@class='wallet-app-item-info']/p[.='Tezos wallet']");

//script to click Connect button by Javascript
const script =
    '''document.querySelector("div[id*='beacon-alert-wrapper']")?.shadowRoot?.querySelector("a[id*='button_'] > button[class*='connect__btn']").click();''';

Future<void> linkBeaconWalletFromExchange(
  AppiumWebDriver driver,
  String exchange,
) async {
  await driver.app.activate(CHROME_APPPACKAGE);
  sleep(Duration(seconds: 2));

  await driver.contexts.setContext("CHROMIUM");
  await driver.timeouts.setPageLoadTimeout(Duration(seconds: 60));
  await driver.timeouts.setScriptTimeout(Duration(seconds: 30));
  await driver.get("https://$exchange");

  //need to wait long time because sometime mobile browser loads website too long because of network
  //sleep(Duration(seconds: 20));
  await Future.delayed(Duration(seconds: 10));
  if (exchange == "objkt.com") {
    var objktHamburgerIcon =
        await driver.findElement(objktHamburgerIconLocator);
    await objktHamburgerIcon.click();
    var objktSyncButton = await driver.findElement(objktSyncButtonLocator);
    await objktSyncButton.click();
  } else if (exchange == "fxhash.xyz") {
    var fxhashHamburgerIcon =
        await driver.findElement(fxhashHamburgerIconLocator);
    await fxhashHamburgerIcon.click();
    sleep(Duration(seconds: 1));
    var fxhashSyncButton = await driver.findElement(fxhashSyncButtonLocator);
    await fxhashSyncButton.click();
  } else if (exchange == "teia.art") {
    var teiaSyncButton = await driver.findElement(teiaSyncButtonLocator);
    await teiaSyncButton.click();
  } else if (exchange == "versum.xyz") {
    var versumSyncButton = await driver.findElement(versumSyncButtonLocator);
    await versumSyncButton.click();
  } else if (exchange == "akaswap.com") {
    var akaswapSyncButton = await driver.findElement(akaswapSyncButtonLocator);
    await akaswapSyncButton.click();
  } else if (exchange == "typed.art") {
    var typedartSyncButton =
        await driver.findElement(typedartSyncButtonLocator);
    await typedartSyncButton.click();
  } else if (exchange == "hicetnunc.cc") {
    await driver.switchTo.alert.dismiss();
    var hicetnuncSyncButton =
        await driver.findElement(hicetnuncSyncButtonLocator);
    await hicetnuncSyncButton.click();
  } else if (exchange == "feralfile.staging.bitmark.com/exhibitions"){
    var FFsignInButton = await driver.findElement(FFsigninLocator);
    await FFsignInButton.click();
    var FFconnectWalletButton = await driver.findElement(FFconnectYourWalletLocator);
    await FFconnectWalletButton.click();
    var FFtezosWallet = await driver.findElement(FFtezosWalletLocator);
    await FFtezosWallet.click();
  }

  sleep(Duration(seconds: 2));

  await driver.execute(script, []);

  // Wait for app reload
  // sleep(Duration(seconds: 10));

  await driver.contexts.setContext("NATIVE_APP");

  //This is for handling Generate account flow. For now, we temporary ignore this flow
  /* int isGenerateButtonDisplayed =
      await driver.findElements(AppiumBy.accessibilityId("GENERATE")).length;
  if (isGenerateButtonDisplayed == 1) {
    print("Da vao check Generate");

    AppiumWebElement generateButton =
        await driver.findElement(AppiumBy.accessibilityId("GENERATE"));
    await generateButton.click();
    sleep(Duration(seconds: 3));
    AppiumWebElement continueButton =
        await driver.findElement(AppiumBy.accessibilityId("CONTINUE"));
    await continueButton.click();
  } */

  sleep(Duration(seconds: 2));
  AppiumWebElement connectButton =
      await driver.findElement(connectButtonLocator);
  await connectButton.click();

  //FXhash, teia.art no need sign
  if (exchange != "fxhash.xyz" &&
      exchange != "teia.art" &&
      exchange != "akaswap.com" &&
      exchange != "typed.art" &&
      exchange != "hicetnunc.cc") {
    sleep(Duration(seconds: 10));
    AppiumWebElement signButton = await driver.findElement(signButtonLocator);
    await signButton.click();
  }
}
