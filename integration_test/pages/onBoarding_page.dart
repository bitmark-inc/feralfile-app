//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import 'package:flutter_test/flutter_test.dart';

import '../commons/test_util.dart';

final Finder autonomyHeader = find.text('AUTONOMY');
final Finder startButton = find.text("START");
final Finder continueButton = find.text("CONTINUE");
final Finder notNowButton = find.text("NOT NOW");
final Finder createAccountButton = find.text("No");
final Finder skipButton = find.text("SKIP");
final Finder restoreButton = find.text("RESTORE");
final Finder nftCollections = find.text("Collection");
final Finder conflictDetectHeader = find.text('Conflict detected');
final Finder continueWithouItbutton = find.text("CONTINUE WITHOUT IT");

Future<void> onboardingSteps(WidgetTester tester) async {
  // Temporary ignore the survey and the Enable notification page to make the application stable to test.
  await injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);
  await injector<ConfigurationService>().setNotificationEnabled(false);
  if (startButton.evaluate().isNotEmpty) {
    // Fresh start
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton);
      await tester.pumpAndSettle();
    }

    await tester.tap(createAccountButton);

    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    await tester.tap(continueWithouItbutton);
    await tester.pumpAndSettle(Duration(seconds: 5));
    sleep(Duration(seconds: 3));

    expect(nftCollections, findsOneWidget);
  } else if (restoreButton.evaluate().isNotEmpty) {
    //Restore

    await tester.tap(restoreButton);
    await tester.pumpAndSettle(Duration(seconds: 3));

    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton);
      await tester.pumpAndSettle(Duration(seconds: 8));
    }
  }
  await handleConflictDetected(tester);
}
