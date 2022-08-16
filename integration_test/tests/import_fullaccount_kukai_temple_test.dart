//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../commons/test_util.dart';
import '../pages/access_method_page.dart';
import '../pages/onboarding_page.dart';
import '../test_data/test_constants.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Verify that user is able to restore account by imported Seed", () {
    testWidgets("for a Full account", (tester) async {
      await initAppAutonomy(tester);
      await launchAutonomy(tester);
      await onboardingSteps(tester);

      await selectSubSettingMenu(tester, "Settings->+ Account->Add");

      Future<String> accountAliasf = genTestDataRandom("Full");
      String accountAlias = await accountAliasf;

      await restoreAccountBySeeds(
          tester, "MetaMask", SEEDS_TO_RESTORE_FULLACCOUNT, accountAlias);

      // Check account restore successful
      expect(find.text(accountAlias), findsOneWidget);
    });
    testWidgets("for a Kukai account", (tester) async {
      await launchAutonomy(tester);
      await onboardingSteps(tester);

      await selectSubSettingMenu(tester, "Settings->+ Account->Add");

      Future<String> accountAliasf = genTestDataRandom("Kukai");
      String accountAlias = await accountAliasf;

      await restoreAccountBySeeds(
          tester, "Kukai", SEED_TO_RESTORE_KUKAI, accountAlias);

      // Check account restore successful
      expect(find.text(accountAlias), findsOneWidget);
    });
    testWidgets("for a Temple account", (tester) async {
      await initAppAutonomy(tester);
      await launchAutonomy(tester);
      await onboardingSteps(tester);

      await selectSubSettingMenu(tester, "Settings->+ Account->Add");

      Future<String> accountAliasf = genTestDataRandom("Temple");
      String accountAlias = await accountAliasf;

      await restoreAccountBySeeds(
          tester, "Temple", SEED_TO_RESTORE_TEMPLE, accountAlias);

      // Check account restore successful
      expect(find.text(accountAlias), findsOneWidget);
    });
  });
}
