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

AppiumBy addLinkLocator = AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'I already have NFTs in other wallets')]");
AppiumBy metaMaskButtonLocator = AppiumBy.accessibilityId("MetaMask");
AppiumBy linkAccountLinkLocator = AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'View your NFTs without Autonomy accessing your private keys in MetaMask.')]");
AppiumBy mobileLinkLocator =
    AppiumBy.accessibilityId("Mobile app on this device");
AppiumBy metaMaskApproveButtonLocator = AppiumBy.xpath(
    "//android.view.ViewGroup[contains(@resource-id,'connect-approve-button')]");
AppiumBy accountLinkedHeaderLocator =
    AppiumBy.accessibilityId("Account linked");
AppiumBy skipButtonLocator = AppiumBy.accessibilityId("SKIP");
AppiumBy alreadyLinkedHeaderLocator =
    AppiumBy.accessibilityId("Already linked");

Future<void> addExistingMetaMaskAccount(
    AppiumWebDriver driver, String type, String metaMaskAlias) async {
  var addLink = await driver.findElement(addLinkLocator);
  addLink.click();
  // sleep(Duration(seconds: 1));
  var metaMaskButton = await driver.findElement(metaMaskButtonLocator);
  metaMaskButton.click();

  var linkAccountLink = await driver.findElement(linkAccountLinkLocator);
  linkAccountLink.click();

  if (type == "app") {
    var mobileLink = await driver.findElement(mobileLinkLocator);
    mobileLink.click();

    var metaMaskApproveButton =
        await driver.findElement(metaMaskApproveButtonLocator);
    metaMaskApproveButton.click();
  } else {
    // This for block code we will handle link metamask account by web browser
  }

  var accountLinked =
      await driver.findElements(accountLinkedHeaderLocator).length;
  expect(accountLinked, 1);

  sleep(Duration(seconds: 5));
  if (metaMaskAlias.isNotEmpty) {
    typeAccountAlias(driver, metaMaskAlias);
  } else {
    var skipButton = await driver.findElement(skipButtonLocator);
    await skipButton.click();
  }
}
