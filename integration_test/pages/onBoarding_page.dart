//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/main.dart' as app;
import '../commons/test_util.dart';

final Finder autonomyheader = find.text('AUTONOMY');
final Finder startbutton = find.text("START");
final Finder continuebutton = find.text("CONTINUE");
final Finder notnowbutton = find.text("NOT NOW");
final Finder createaccountbutton = find.text("No");
final Finder skipbutton = find.text("SKIP");
final Finder restorebutton = find.text("RESTORE");
final Finder nftcollections = find.text("Collection");
final Finder conflictdetectheader = find.text('Conflict detected');
final Finder continueWithouItbutton = find.text("CONTINUE WITHOUT IT");

Future<void> onboardingSteps(WidgetTester tester) async {
  // await initAppAutonomy(tester);
  //expect(autonomyheader, findsOneWidget);

  // Temporary ignore the survey and the Enable notification page to make the application stable to test.
  await injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);
  await injector<ConfigurationService>().setNotificationEnabled(false);
  if (startbutton.evaluate().isNotEmpty) {
    // Fresh start
    await tester.tap(startbutton);

    await tester.pumpAndSettle();

    await tester.tap(continuebutton);

    await tester.pumpAndSettle();

    if (notnowbutton.evaluate().isNotEmpty) {
      await tester.tap(notnowbutton);
      await tester.pumpAndSettle();
    }

    await tester.tap(createaccountbutton);

    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(continuebutton);

    await tester.pumpAndSettle();

    await tester.tap(skipbutton);

    await tester.pumpAndSettle();

    await tester.tap(continueWithouItbutton);

    await tester.pumpAndSettle(Duration(seconds: 5));
    sleep(Duration(seconds: 3));

    expect(nftcollections, findsOneWidget);
  } else if (restorebutton.evaluate().isNotEmpty) {
    //Restore

    await tester.tap(restorebutton);

    await tester.pumpAndSettle(Duration(seconds: 3));
    //wait for Not now notification appear to close
    // sleep(Duration(seconds: 5));

    if (notnowbutton.evaluate().isNotEmpty) {
      await tester.tap(notnowbutton);
      await tester.pumpAndSettle(Duration(seconds: 8));
    }
  }
  await handleConflictDetected(tester);
}
