//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../commons/test_util.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_constants.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
      "Verify that user open Artwork detail without spinner after timeout time - ",
      () {
    testWidgets("Image", (tester) async {
      await initAppAutonomy(tester);
      await launchAutonomy(tester);
      await onboardingSteps(tester);

      for (var id in LIST_CHECK_ARTWORKSID_ADD_MANUAL) {
        await addDelay(2000);
        await selectSubSettingMenu(tester, "Settings->+ Account");

        await tester.tap(find.text('Delete All Debug Linked IndexerTokenIDs'));
        await tester.pumpAndSettle(Duration(seconds: 3));
        await tester.tap(find.text('Debug Indexer TokenID'));
        await tester.pumpAndSettle(Duration(seconds: 3));

        await tester.enterText(find.byType(TextField), id);

        await tester.tap(find.text('LINK'));
        await tester.pump(Duration(seconds: 10));
        await tester.pump(Duration(seconds: 10));

        // Add delay to load after link TokenID
        await addDelay(5000);

        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle(Duration(seconds: 5));
        await tester.pump(Duration(seconds: 5));

        // add delay to wait for artwork display
        await addDelay(5000);

        await tester.ensureVisible(find.byType(CachedNetworkImage));
        await tester.pump(const Duration(milliseconds: 4000));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(CachedNetworkImage));
        // Pump Pump2 times because application is not stable
        await tester.pump();
        await tester.pump();

        // Add delay to wait for Artwork loading successful
        await addDelay(5000);
        print(
            "This is a bug happens in only Automation test, the artwork does not display after adding debug TokenID");
        expect(find.byType(CircularProgressIndicator).evaluate().length, 0);
        await tester.tap(find.byTooltip('CloseArtwork'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
      }
    });
  });
}
