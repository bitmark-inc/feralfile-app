// UI inspect is here
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder settings_icon = find.byTooltip("Settings");
final Finder back_button = find.text("BACK");
final Finder new_button =
    find.textContaining("Make a new account with addresses you can use");
final Finder continue_button = find.text("CONTINUE");
final Finder alias_textbox = find.byType(TextField);
final Finder saveAlias_button = find.text("SAVE ALIAS");
final Finder skip_button = find.text("SKIP");
final Finder openDeviceSetting_button = find.text("OPEN DEVICE SETTINGS");
final Finder continueWithouIt_button = find.text("CONTINUE WITHOUT IT");

Future<void> addANewAccount(
    WidgetTester tester, String accountType, String alias) async {
  // Do actions in here

  if (accountType == 'new') {
    await tester.tap(new_button);
    // await tester.pumpAndSettle();
    // sleep(Duration(seconds: 10));
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    log('over New account');
    log('over New account');
    log('over New account');
    log('over New account');
    log('over New account');
    log('over New account');

    // await tester.pumpAndSettle();
    await tester.tap(continue_button);
    // await tester.pump();
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(alias_textbox, alias);
    // await tester.pumpAndSettle(Duration(seconds: 4));
    // await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(saveAlias_button);
    // await tester.pumpAndSettle();
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    if (continueWithouIt_button.evaluate().isNotEmpty) {
      await tester.tap(continueWithouIt_button);
      // sleep(Duration(seconds: 3));
    }
  } else {}
}
