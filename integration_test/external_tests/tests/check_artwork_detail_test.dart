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
import '../test_data/test_configurations.dart';
import '../test_data/test_constants.dart';
import '../pages/artwork_page.dart';

void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Check artwork detail ", () {
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

    test('Image', () async {
      await onBoardingSteps(driver);

      for (var tokenID in LIST_CHECK_ARTWORKSID_ADD_MANUAL) {
        await selectSubSettingMenu(driver, "Settings->+ Account");
        AppiumBy deleteAllDebugLinkedLocator = AppiumBy.xpath(
            '//android.widget.Button[contains(@content-desc, "Delete All Debug")]');
        var deleteAllDebugLinked = await driver.findElements(deleteAllDebugLinkedLocator).first;
        await deleteAllDebugLinked.click();

        AppiumBy debugIndexerLocator = AppiumBy.xpath('//android.widget.ImageView[contains(@content-desc, "Debug Indexer TokenID")]');
        var debugIndexer = await driver.findElements(debugIndexerLocator).first;
        await debugIndexer.click();
        var pasteIndexerTokenID = await driver
            .findElements(
            AppiumBy.className('android.widget.EditText'))
            .first;
        await pasteIndexerTokenID.click();
        await pasteIndexerTokenID.sendKeys(tokenID);
        await driver.keyboard.sendKeys('\n');

        var linkButton = await driver.findElement(
            AppiumBy.accessibilityId('LINK'));
        await linkButton.click();

        var closeSetting = await driver.findElements(AppiumBy.xpath(
            '//android.widget.ImageView[@content-desc="Settings"]')).first;
        await closeSetting.click();

        await timeDelay(ARTWORK_LOADING_TIME_LIMIT);
        AppiumBy loadingImageLocator = AppiumBy.xpath('//android.widget.ImageView[@content-desc="Settings"]/../android.view.View/android.view.View/android.view.View');
        var loadingImage = await driver.findElements(loadingImageLocator).length;
        expect(loadingImage, 0);

        AppiumBy artworkLocator = AppiumBy.xpath(
            '//android.widget.ImageView[@content-desc="Settings"]/../android.view.View/android.view.View/android.widget.ImageView[2]');
        var artwork = await driver.findElements(artworkLocator).first;
        await artwork.click();
        
        await timeDelay(ARTWORK_LOADING_TIME_LIMIT);
        var hasloading = await driver.findElements(AppiumBy.accessibilityId('loading...')).length;
        expect(hasloading, 0);

        var closeArtwork = await driver.findElement(AppiumBy.accessibilityId('CloseArtwork'));
        await closeArtwork.click();
      }
    });
  }, timeout: Timeout.none);
}
