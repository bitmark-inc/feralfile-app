//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../pages/onboarding_page.dart';

import '../commons/test_util.dart';
import '../pages/setting_page.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Create a new full account", () {
    // testWidgets(" with alias", (tester) async {
    //   await onboardingSteps(tester);
    //   await selectSubSettingMenu(tester, "Settings->+ Account");
    //   Future<String> accountAliasf = genTestDataRandom("account");
    //   String accountAlias = await accountAliasf;
    //   await addANewAccount(tester, 'new', accountAlias);

    //   expect(find.text(accountAlias), findsOneWidget);

    //   await deleteAnAccount(accountAlias);
    // });

    testWidgets("Create a new full account without alias", (tester) async {
      await onboardingSteps(tester);

      await tester.tap(find.byTooltip("Settings"));
      await tester.pump(Duration(seconds: 5));

      int beforeAddAccount = await getNumberOfAccount();
      await selectSubSettingMenu(tester, "+ Account");

      await addANewAccount(tester, 'skip', "");
      int afterAddAccount = await getNumberOfAccount();
      beforeAddAccount = beforeAddAccount + 1;
      expect(afterAddAccount, beforeAddAccount);
    });
  });
}
