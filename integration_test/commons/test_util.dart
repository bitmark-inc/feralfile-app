//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
    // if (menu.indexOf('->') < 0) await tester.tap(find.text(menu));
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

Future<void> deleteAnAccount(String accountAlias) async {}
