//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:math';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import '../../lib/main.dart' as app;

import 'package:autonomy_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

final Finder autonomyheader = find.text('AUTONOMY');
final Finder conflictdetectheader = find.text('Conflict detected');
final Finder devicekeychainradio = find.descendant(
  of: find.text('Device keychain'),
  matching: find.byType(Radio),
);
final Finder cloudkeychain = find.descendant(
  of: find.text('Cloud keychain'),
  matching: find.byType(Radio),
);
final Finder proceedbutton = find.text("PROCEED");

Future<void> addDelay(int ms) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}

Future<void> depositTezos(String address) async {
  final faucetUrl = dotenv.env['TEZOS_FAUCET_URL'] ?? '';
  final token = dotenv.env['TEZOS_FAUCET_AUTH_TOKEN'] ?? '';

  await http.post(
    Uri.parse(faucetUrl),
    body: json.encode({"address": address}),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic $token",
    },
  );
}

Future<void> selectSubSettingMenu(WidgetTester tester, String menu) async {
  String sub_menu = await menu;
  while (menu.indexOf('->') > 0) {
    int index = await menu.indexOf('->');
    sub_menu = await menu.substring(0, index);
    menu = await menu.substring(menu.indexOf('->') + 2, menu.length);

    if (sub_menu == "Settings") {
      await tester.tap(find.byTooltip("Settings"));
      // await tester.pump(Duration(seconds: 5));
    } else
      await tester.tap(find.text(sub_menu));
    await tester.pump(Duration(seconds: 5));
  }
  await tester.tap(find.text(menu));
  await tester.pumpAndSettle();
}

Future<String> genTestDataRandom(String baseString) async {
  var rng = Random();

  baseString = baseString + rng.nextInt(10000).toString();
  print(baseString);
  return baseString;
}

Future<void> handleConflictDetected(WidgetTester tester) async {
  if (conflictdetectheader.evaluate().isNotEmpty) {
    // tester.tap(devicekeychainradio);
    // tester.tap(cloudkeychain);
    // tester.tap(devicekeychainradio);
    await tester.tap(proceedbutton);
    await tester.pumpAndSettle(Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}

Future<void> launchAutonomy(WidgetTester tester) async {
  await tester.pumpWidget(AutonomyApp());
  await tester.pumpAndSettle(Duration(seconds: 7));
}

Future<void> initAppAutonomy(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(Duration(seconds: 5));
}

Future<void> deleteAnAccount(String accountAlias) async {}
