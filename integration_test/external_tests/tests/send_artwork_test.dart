//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../pages/onboarding_page.dart';
import '../pages/settings_page.dart';
import '../test_data/modals/ArtworkTestMetadata.dart';
import '../test_data/test_configurations.dart';
import '../test_data/test_constants.dart';

void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Verify that user is able to send an artwork -", () {
    setUp(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 10));
    });

    tearDown(() async {
      await driver.app.remove(AUTONOMY_APPPACKAGE);
      await driver.quit();
    });

    for (int i = 1; i <= 2; i++) {
      test('own tokens subtracts $i artworks', () async {
        await onBoardingSteps(driver);

        await selectSubSettingMenu(driver, "Settings->+ Account");

        Future<String> metaAccountAliasf = genTestDataRandom("Meta");
        String metaAccountAlias = await metaAccountAliasf;

        await importAnAccountBySeeds(
            driver, "MetaMask", SEEDS_TO_RESTORE_FULLACCOUNT, metaAccountAlias);

        var settingIcon = await driver.findElement(settingButtonLocator);
        await settingIcon.click();

        //Need to wait artworks Collection loads
        await Future.delayed(const Duration(seconds: 15));

        ArtworkTestMetadata artworkDataPrevious =
            await fetchArtwork(URL_BALANCE_SOURCE_ACCOUNT);

        await sendAwrtwork(
            driver, TEZ_SEND_ARTWORK_NAME, TEZ_TARGET_ADDRESS, i);

        int isMessageHeaderSuccessDisplay = await driver
            .findElements(AppiumBy.accessibilityId("Success!"))
            .length;
        expect(isMessageHeaderSuccessDisplay, 1);

        int isMessageSuccessDisplay = await driver
            .findElements(AppiumBy.xpath(
                "//android.view.View[@content-desc='Your transaction has been processed and you can see the details in your account history.']"))
            .length;
        expect(isMessageSuccessDisplay, 1);

        int isButtonSeeTrans = await driver
            .findElements(AppiumBy.accessibilityId("SEE TRANSACTION DETAIL"))
            .length;
        expect(isButtonSeeTrans, 1);

        var buttonSesTrans = await driver
            .findElement(AppiumBy.accessibilityId("SEE TRANSACTION DETAIL"));
        await buttonSesTrans.click();

        int isSendNFTHeaderDisplay = await driver
            .findElements(AppiumBy.accessibilityId("Sent NFT"))
            .length;
        expect(isSendNFTHeaderDisplay, 1);

        int isTargetAddressCorrect = await driver
            .findElements(AppiumBy.xpath(
                "//android.view.View[contains(@content-desc,'$TEZ_TARGET_ADDRESS')]"))
            .length;
        expect(isTargetAddressCorrect, 1);

        int isStatusPendingCorrect = await driver
            .findElements(AppiumBy.xpath(
                "//android.view.View[contains(@content-desc,'Pending')]"))
            .length;
        expect(isStatusPendingCorrect, 1);

        int isAmountCorrect = await driver
            .findElements(AppiumBy.xpath(
                "//android.view.View[contains(@content-desc,'Token amount') and contains(@content-desc,'$i')]"))
            .length;
        expect(isStatusPendingCorrect, 1);

        await wait4TezBlockchainConfirmation(driver);

        ArtworkTestMetadata artworkData =
            await fetchArtwork(URL_BALANCE_SOURCE_ACCOUNT);

        int artworkRemainingOwn = int.parse(artworkDataPrevious.balance) - i;
        expect(artworkData.balance, artworkRemainingOwn.toString());

        var buttonBack = await driver.findElement(
            AppiumBy.xpath("//android.widget.ImageView[@content-desc='BACK']"));
        await buttonBack.click();

        // After some cycle when we have solution to update artwork thumbnail/metadata realtime,
        //we will need to check in UI for both sent account and received account
      });
    }
  }, timeout: Timeout.none);
}
