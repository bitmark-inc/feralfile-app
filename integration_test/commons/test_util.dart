import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
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
    debugPrint(sub_menu);
    debugPrint(sub_menu);
    debugPrint(sub_menu);
    log(sub_menu);
    debugPrint(sub_menu);
    log(sub_menu);
    log(sub_menu);
    log(sub_menu);
    log(sub_menu);
    log(sub_menu);

    debugPrint(menu);
    debugPrint(menu);
    debugPrint(menu);
    log(menu);
    debugPrint(menu);
    log(menu);
    log(menu);
    log(menu);
    log(menu);
    log(menu);

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
