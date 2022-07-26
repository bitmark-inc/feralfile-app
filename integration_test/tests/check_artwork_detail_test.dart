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

      await selectSubSettingMenu(tester, "Settings->+ Account->Add");
      await restoreAccountBySeeds(
          tester, 'MetaMask', SEEDS_TO_RESTORE_FOR_TEST);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key(IMAGE_ARTWORK)));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
