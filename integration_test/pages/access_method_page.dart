import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../commons/test_util.dart';
import '../test_data/test_constants.dart';
import 'setting_page.dart';

final Finder seedstextbox = find.byType(TextField);
final Finder confirmbutton = find.text('CONFIRM');

Future<void> restoreAccountBySeeds(
    WidgetTester tester, String accountType, String seedsdata) async {
  await tester.tap(find.text(accountType));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Import'));
  await tester.pumpAndSettle();

  await tester.enterText(seedstextbox, SEEDS_TO_RESTORE_FOR_TEST);

  await tester.tap(confirmbutton);
  await addDelay(5);
  await tester.tap(confirmbutton);
  await tester.pumpAndSettle(Duration(seconds: 4));
  await tester.pumpAndSettle(Duration(seconds: 1));
  // await addDelay(5);
  await tester.tap(skipbutton);
  await tester.pumpAndSettle(Duration(seconds: 4));
  await tester.pumpAndSettle(Duration(seconds: 1));

  await tester.tap(continueWithouItbutton);
  await tester.pump(Duration(seconds: 4));
}
