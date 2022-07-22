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

final Finder autonomy_header = find.text('AUTONOMY');
final Finder startButton = find.text("START");
final Finder continueButton = find.text("CONTINUE");
final Finder notNowButton = find.text("NOT NOW");
final Finder createAccountButton = find.text("No");
final Finder continueButton2 = find.text("CONTINUE");
final Finder skipButton = find.text("SKIP");
final Finder continueButton3 = find.text("CONTINUE");
final Finder restoreButton = find.text("RESTORE");
final Finder NFTCollections = find.text("Collection");

Future<void> onboardingSteps(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(Duration(seconds: 5));
  await tester.pumpWidget(AutonomyApp());
  await tester.pumpAndSettle(Duration(seconds: 3));

  expect(autonomy_header, findsOneWidget);

  await injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);

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

    await tester.tap(continueButton2);

    await tester.pumpAndSettle();

    await tester.tap(skipButton);

    await tester.pumpAndSettle();

    await tester.tap(continueButton3);

    await tester.pumpAndSettle(Duration(seconds: 5));
    sleep(Duration(seconds: 3));

    expect(NFTCollections, findsOneWidget);
  } else {
    //Restore

    await tester.tap(restoreButton);

    await tester.pumpAndSettle(Duration(seconds: 3));
    //wait for Not now notification appear to close
    sleep(Duration(seconds: 5));

    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton);
      await tester.pumpAndSettle(Duration(seconds: 5));
      // sleep(Duration(seconds: 5));
    }
  }
}
