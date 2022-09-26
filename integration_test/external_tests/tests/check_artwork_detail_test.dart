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
<<<<<<< HEAD
      //await driver.app.remove(AUTONOMY_APPPACKAGE);
=======
      await driver.app.remove(AUTONOMY_APPPACKAGE);
>>>>>>> 16dd25748f46ea8200354b2ce12310424c43038b
      await driver.quit();
    });

    test('Image', () async {
      await onBoardingSteps(driver);

      for (var tokenID in LIST_CHECK_ARTWORKSID_ADD_MANUAL) {
        await selectSubSettingMenu(driver, "Settings->+ Account");
        await deleteAllDebugAddress(driver);
        await goBack(driver, 2);

        int numberArtwork = await countArtwork(driver);
        expect(numberArtwork, 0);

        await selectSubSettingMenu(driver, "Settings->+ Account");
        await importArtwork(driver, tokenID);
        var closeSetting = await driver.findElements(AppiumBy.xpath(
            '//android.widget.ImageView[@content-desc="Settings"]')).first;
        await closeSetting.click();

        await timeDelay(ARTWORK_LOADING_TIME_LIMIT);
        int numberArtworkAfterImport = await countArtwork(driver);
        expect(numberArtwork + 1, numberArtworkAfterImport);

        int hasScrollView = await driver.findElements(AppiumBy.xpath('//android.widget.ScrollView')).length;
        if (hasScrollView == 0) {
          var artwork = await driver.findElements(artworkGridLocator).elementAt(1);
          await artwork.click();
        }
        else{
          var artwork = await driver.findElements(AppiumBy.xpath(
              'android.widget.ScrollView/android.widget.ImageView')).elementAt(1);
          await artwork.click();
        }

        await timeDelay(ARTWORK_LOADING_TIME_LIMIT);
        var hasloading = await driver.findElements(AppiumBy.accessibilityId('loading...')).length;
        expect(hasloading, 0);

        var isInterective = await isInterectiveArtwork(driver);
        expect(isInterective, IS_INTERACTIVE_ARTWORK[tokenID]);

        var closeArtwork = await driver.findElement(AppiumBy.accessibilityId('CloseArtwork'));
        await closeArtwork.click();
      }
    });
  }, timeout: Timeout.none);
}
