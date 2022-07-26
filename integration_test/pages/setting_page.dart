//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

// UI inspect is here
final Finder settingsicon = find.byTooltip("Settings");
final Finder backbutton = find.text("BACK");
final Finder newbutton =
    find.textContaining("Make a new account with addresses you can use");
final Finder continuebutton = find.text("CONTINUE");
final Finder aliastextbox = find.byType(TextField);
final Finder saveAliasbutton = find.text("SAVE ALIAS");
final Finder skipbutton = find.text("SKIP");
final Finder openDeviceSettingbutton = find.text("OPEN DEVICE SETTINGS");
final Finder continueWithouItbutton = find.text("CONTINUE WITHOUT IT");

Future<void> addANewAccount(
    WidgetTester tester, String accountType, String alias) async {
  // Do actions in here

  if (accountType == 'new') {
    await tester.tap(newbutton);

    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(continuebutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(aliastextbox, alias);

    await tester.tap(saveAliasbutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    if (continueWithouItbutton.evaluate().isNotEmpty) {
      await tester.tap(continueWithouItbutton);
      await tester.pump(Duration(seconds: 4));
    }
  } else if (accountType == 'skip') {
    await tester.tap(newbutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(continuebutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(skipbutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    if (continueWithouItbutton.evaluate().isNotEmpty) {
      await tester.tap(continueWithouItbutton);
      await tester.pump(Duration(seconds: 4));
    }
  }
}

Future<int> getNumberOfAccount() async {
  // Do actions in here
  int b = find
      .descendant(
          of: find.byType(SlidableAutoCloseBehavior),
          matching: find.byType(Slidable))
      .evaluate()
      .length;
  return b;
}
