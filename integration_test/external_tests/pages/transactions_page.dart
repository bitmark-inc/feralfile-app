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

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../test_data/test_constants.dart';

var monthMap = {
  'jan':'01',
  'feb':'02',
  'mar':'03',
  'apr':'04',
  'may':'05',
  'jun':'06',
  'jul':'07',
  'aug':'08',
  'sep':'09',
  'oct':'10',
  'nov':'11',
  'dec':'12',
};

RegExp XTZExp = RegExp(r'[+-]*[0-9]+[.][0-9]*');
RegExp XTZExp2 = RegExp(r'[+-]*[0-9]+.[0-9]* XTZ');


String yearExp = "(\\d{4})";
String monthExp =  '(jan(?:uary)?|'
    'feb(?:ruary)?|'
    'mar(?:ch)?|'
    'apr(?:il)?|'
    'may|'
    'jun(?:e)?|'
    'jul(?:y)?|'
    'aug(?:ust)?|'
    'sep(?:tember)?|'
    'oct(?:ober)?|'
    '(nov|dec)(?:ember)?)';
String mountExp2 = "(0[1-9]|1[0-2])";
String dayExp = "(0[1-9]|[12][0-9]|3[01])";
String hourExp = "(0[0-9]|1[0-9]|2[0-4])";
String minuteExp = "([0-5][0-9])";
String timeExp = "$hourExp:$minuteExp";
var DATE_TIME_EXP = RegExp('$yearExp-($monthExp|$mountExp2)-$dayExp $hourExp:$minuteExp');

var MMDDhhmm_REG = RegExp('$monthExp $dayExp $timeExp');

Future<double> getFee(AppiumWebDriver driver) async {
  AppiumWebElement gasFee = await getElementByContentDesc(driver, 'fee');
  String desc = await gasFee.attributes['content-desc'];
  String feeStr = (XTZExp.stringMatch(desc) as String);
  var fee = double.parse(feeStr);
  return fee;
}

Future<List<Object>> sendTezos(AppiumWebDriver driver, String address, [double amount = -1]) async {
  AppiumBy sendLocator = AppiumBy.accessibilityId('SEND');
  AppiumWebElement sendButton = await driver.findElement(sendLocator);
  sendButton.click();

  AppiumBy editTextLocator = AppiumBy.className('android.widget.EditText');
  AppiumWebElement toAddress = await driver.findElements(editTextLocator).first;

  await toAddress.click();
  await toAddress.sendKeys(address);
  await driver.keyboard.sendKeys('\n');

  AppiumBy reviewButtonLocator = AppiumBy.accessibilityId("REVIEW");
  var reviewButton = await driver.findElement(reviewButtonLocator);
  var isClickable = await reviewButton.attributes['clickable'];
  expect(isClickable, 'false'); // Review is unClickable

  if (amount < 0){
    amount = await getMax(driver);
  }
  AppiumWebElement sendTxt = await driver.findElements(editTextLocator).elementAt(1); //TODO
  await sendTxt.click();
  await sendTxt.sendKeys(await amount.toString());
  await driver.keyboard.sendKeys('\n');
  double fee = await getFee(driver);

  // Click on Review Button
  reviewButton = await driver.findElement(reviewButtonLocator);
  isClickable = await reviewButton.attributes['clickable'];
  expect(isClickable, 'true');
  await reviewButton.click();

  sendButton = await driver.findElement(sendLocator);
  var sendtime = DateTime.now();
  await sendButton.click();
  return [fee, sendtime, amount];
}


Future<AppiumWebElement> getRecentTransaction(AppiumWebDriver driver, [String type = ""]) async {
  if (!(type == 'Sent' || type == "Received" || type == "")){
    type = '';
    expect(1, 2);
  }

  await driver.back();
  var historyButton = await getElementByContentDesc(driver, "History");
  historyButton.click();
  await timeDelay(4);
  // At Transaction Page
  await scrollUntil(driver, "$type");

  AppiumWebElement scrollEle = await driver.findElements(
      AppiumBy.className('android.widget.ScrollView')).first;

  AppiumBy recentTransactionLocator = AppiumBy.xpath(
      '//android.widget.ImageView[contains(@content-desc, "$type XTZ")]');

  var allTransaction = scrollEle.findElements(recentTransactionLocator);
  var recentTransaction = await allTransaction.first;
  return recentTransaction;
}


Future<void> expectTransaction(AppiumWebDriver driver, String address, DateTime date, double amount) async {
  int hasStatus = await driver.findElements(AppiumBy.xpath(
      '//android.view.View[contains(@content-desc, "Applied")]')).length;
  expect(hasStatus, 1);

  int hasAddress = await driver.findElements(AppiumBy.xpath(
      '//android.view.View[contains(@content-desc, "$address")]')).length;
  expect(hasAddress, 1);

  var amountTxt =await getElementByContentDesc(driver, "Amount");
  String amountTxtDesc = await amountTxt.attributes['content-desc'];
  double foundAmount = await getTezosFromString(amountTxtDesc);
  expect((amount - foundAmount).abs() <= EPS, true);

  AppiumWebElement dateEle = await driver.findElements(AppiumBy.xpath(
      '//android.view.View[contains(@content-desc, "Date")]')).first;
  String desc = await dateEle.attributes['content-desc'];
  DateTime senddate = toDateTime(desc);

  var timeDiff = await date.difference(senddate).inMinutes;
  expect(timeDiff.abs() < 2, true);
}

Future<void> expectReceiveTransaction(AppiumWebDriver driver, String address, DateTime date, double amount) async {
  await expectTransaction(driver, address, date, amount);
}

Future<void> expectSentTransaction(AppiumWebDriver driver, String address, DateTime date, double amount, double fee) async {
  await expectTransaction(driver, address, date, amount);

  var feeEle = await driver.findElements(AppiumBy.xpath(
      '//android.view.View[contains(@content-desc, "Gas fee")]')).first;
  String feeDesc = await feeEle.attributes['content-desc'] as String;
  double fee2 = await getTezosFromString(feeDesc);
  expect((fee-fee2).abs() <= EPS, true);

  double total = await round(amount + fee, 5);
  var totalText = await getElementByContentDesc(driver, 'Total Amount');
  String totalTextDesc = await totalText.attributes['content-desc'];
  double foundTotal = await getTezosFromString(totalTextDesc);
  //print("($total - $foundTotal) = ${(total - foundTotal)}");
  expect((total - foundTotal).abs() <= EPS, true);
}

Future<double> getMax(AppiumWebDriver driver) async
{
  var maxBtn = await getElementByContentDesc(driver, "Max");
  String maxDesc = await maxBtn.attributes['content-desc'];
  var xtzStr = XTZExp.stringMatch(maxDesc);
  expect(xtzStr == null, false);
  return double.parse(xtzStr as String);
}

Future getTezosFromString(String str)async {
  var  tezosStr = XTZExp.stringMatch((XTZExp2.stringMatch(str) as String));
  expect(tezosStr != null, true);
  return double.parse(tezosStr as String);
}

DateTime toDateTime(String text){
  var strMatch = DATE_TIME_EXP.stringMatch(text.toLowerCase()) as String;
  monthMap.forEach((key, value) {
    strMatch = strMatch.replaceAll(key, '$value');
  });
  var time = DateTime.parse(strMatch);
  return time;
}

