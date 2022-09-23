
import 'dart:io';
import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';


AppiumBy artworkGridLocator = AppiumBy.xpath(
    '//android.widget.ImageView[@content-desc="Settings"]/../*/*/android.widget.ImageView');

Future<void> importArtwork(AppiumWebDriver driver, String tokenID) async {
  AppiumBy debugIndexerLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "Debug Indexer TokenID")]');
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
}

Future<void> importArtworks(AppiumWebDriver driver, List<String> tokenIDList) async {
  await selectSubSettingMenu(driver, "Settings");
  for (var tokenID in tokenIDList){
    await selectSubSettingMenu(driver, '+ Account');
    await importArtwork(driver, tokenID);
  }
  var closeSetting = await driver.findElements(AppiumBy.xpath(
      '//android.widget.ImageView[@content-desc="Settings"]')).first;
  await closeSetting.click();
}

Future<void> deleteAllDebugAddress(AppiumWebDriver driver) async {
  AppiumBy deleteAllDebugLinkedLocator = AppiumBy.xpath(
      '//android.widget.Button[contains(@content-desc, "Delete All Debug")]');
  var deleteAllDebugLinked = await driver.findElements(deleteAllDebugLinkedLocator).first;
  await deleteAllDebugLinked.click();
}

Future<int> countArtwork(AppiumWebDriver driver) async {
  // This is count number artworks on screen, not count all
  int res = await driver.findElements(artworkGridLocator).length;
  return res - 1;
}

Future<bool> isInterectiveArtwork(AppiumWebDriver driver) async {
  AppiumBy showToDevicesLocator = AppiumBy.xpath(
      '//android.widget.ImageView[@content-desc="CloseArtwork"]//..//android.widget.ImageView');
  var showToDevices = await driver.findElements(showToDevicesLocator).elementAt(1);
  await showToDevices.click();
  bool res;

  int hasSelectADevice = await driver.findElements(AppiumBy.xpath(
      '//android.view.View[@content-desc="Select a device"]')).length;
  if (hasSelectADevice == 1){
    var cancelButton = await driver.findElement(AppiumBy.xpath(
        '//android.widget.Button[@content-desc="CANCEL"]'));
    await cancelButton.click();
    res = true;
  }
  else{
    int isUnavailable = await driver.findElements(AppiumBy.accessibilityId('Unavailable')).length;
    expect(isUnavailable, 1);
    var okBtutton = await driver.findElement(AppiumBy.accessibilityId('OK'));
    await okBtutton.click();
    res = false;
  }
  return res;
}