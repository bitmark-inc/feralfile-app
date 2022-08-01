//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/widgets.dart';

import '../commons/test_util.dart';
import '../pages/access_method_page.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_constants.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
      "Verify that user open Artwork detail without spinner after timeout time - ",
      () {
    testWidgets("Image", (tester) async {
      await onboardingSteps(tester);

      // await addDelay(5000);
      await selectSubSettingMenu(tester, "Settings->+ Account");
      // await restoreAccountBySeeds(tester, 'MetaMask', SEEDS_TO_RESTORE_FOR_TEST);

      await tester.tap(find.text('Delete All Debug Linked IndexerTokenIDs'));
      await tester.pumpAndSettle(Duration(seconds: 1));
      await tester.tap(find.text('Debug Indexer TokenID'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      await tester.enterText(find.byType(TextField),
          'bmk--899600b02d99d0474c7c0037f6e14829b308286923cd04dc4217845be9c701f8');

      await tester.tap(find.text('LINK'));
      await tester.pumpAndSettle(Duration(seconds: 5));
      await tester.pumpAndSettle(Duration(seconds: 3));

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle(Duration(seconds: 5));
      // await tester.pumpAndSettle(Duration(seconds: 5));
      // await addDelay(10000);

      // for (var artwork in LIST_CHECK_ARTWORKS) {
      //   await tester.tap(find.byKey(Key(artwork)));
      //   await tester.pumpAndSettle();
      //   expect(find.byType(CircularProgressIndicator), findsNothing);
      //   await tester.tap(find.byTooltip('CloseArtwork'));
      //   await tester.pumpAndSettle();
      // }

      await tester.tap(find.byKey(Key('Artwork_Thumbnail')));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.byTooltip('CloseArtwork'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
    });
  });
}
