import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../pages/onBoarding_page.dart';
import 'send_xtz_test.dart';

import '../commons/test_util.dart';
import '../pages/setting_page.dart';
import 'package:autonomy_flutter/main.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Create a new full account", () {
    testWidgets(" with alias", (tester) async {
      await onboardingSteps(tester);
      await selectSubSettingMenu(tester, "Settings->+ Account");
      await addANewAccount(tester, 'new', 'account1');

      expect(find.text('account1'), findsOneWidget);
    });

    // testWidgets("Create a new full account without alias", (tester) async {
    //   await selectSubSettingMenu('Setting->Account->New');
    //   await addANewAccount('default');
    // });
  });
}
