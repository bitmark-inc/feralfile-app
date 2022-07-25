//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../pages/onboarding_page.dart';

import '../commons/test_util.dart';
import '../pages/setting_page.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Create a new full account", () {
    testWidgets(" with alias and check balance", (tester) async {
      await onboardingSteps(tester);
      await selectSubSettingMenu(tester, "Settings->+ Account");
      Future<String> accountAliasf = genTestDataRandom("account");
      String accountAlias = await accountAliasf;
      await addANewAccount(tester, 'new', accountAlias);

      // Check account created successful
      expect(find.text(accountAlias), findsOneWidget);

      await tester.tap(find.text(accountAlias));
      await tester.pumpAndSettle(Duration(seconds: 3));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Check account created successful with 0 balance for ETH and XTZ
      expect(find.text('0.0 ETH'), findsOneWidget);
      expect(find.text('0.0 XTZ'), findsOneWidget);

      // Expect having 3 address are generated and get list will have 3 addresses
      var listAddresses = find.byKey(Key('fullAccount_address'));
      expect(listAddresses.evaluate().length, 3);

      listAddresses.evaluate().forEach((element) {
        expect(element.widget as Text, isNotNull);
      });
      // await deleteAnAccount(accountAlias);
    });

    testWidgets("Create a new full account without alias", (tester) async {
      await onboardingSteps(tester);

      await tester.tap(find.byTooltip("Settings"));
      await tester.pump(Duration(seconds: 5));

      int beforeAddAccount = await getNumberOfAccount();
      await selectSubSettingMenu(tester, "+ Account");

      await addANewAccount(tester, 'skip', "");

      // Get number of account after creating then compare with old data to check the new account is created
      int afterAddAccount = await getNumberOfAccount();
      beforeAddAccount = beforeAddAccount + 1;
      expect(afterAddAccount, beforeAddAccount);
    });
  });
}
