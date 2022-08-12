//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../commons/test_util.dart';
import 'setting_page.dart';

final Finder seedsTextbox = find.byType(TextField);
final Finder confirmButton = find.text('CONFIRM');

Future<void> restoreAccountBySeeds(WidgetTester tester, String accountType,
    String seedsdata, String alias) async {
  await tester.tap(find.text(accountType));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Import'));
  await tester.pumpAndSettle();

  await tester.enterText(seedsTextbox, seedsdata);

  await tester.tap(confirmButton);
  await addDelay(5);
  await tester.tap(confirmButton);
  await tester.pumpAndSettle(Duration(seconds: 4));
  await tester.pumpAndSettle(Duration(seconds: 1));

  if (alias != '') {
    await tester.enterText(aliasTextbox, alias);
  } else {
    await tester.tap(skipButton);
  }
  await tester.pumpAndSettle(Duration(seconds: 4));
  await tester.pumpAndSettle(Duration(seconds: 1));

  if (continueWithouItbutton.evaluate().isNotEmpty) {
    await tester.tap(continueWithouItbutton);
    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pump(Duration(seconds: 4));
    await tester.pump(Duration(seconds: 1));
  }
}
