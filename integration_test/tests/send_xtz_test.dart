import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pages/onBoarding_page.dart';
import '../commons/test_util.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('xtz test', () {
    testWidgets('receive and send xtz', (tester) async {
      await onboardingSteps(tester);

      await tester.tap(find.byTooltip("Settings"));
      await tester.pump(Duration(seconds: 3));

      expect(find.text("Accounts"), findsOneWidget);
      await tester.tap(find.text("Default"));

      await tester.pumpAndSettle();

      final xtzWallet = await (await injector<CloudDatabase>()
              .personaDao
              .getDefaultPersonas())
          .first
          .wallet()
          .getTezosWallet();
      await depositTezos(xtzWallet.address);

      await tester.pumpAndSettle(Duration(seconds: 60));

      final Finder xtzRow = find.text("Tezos (XTZ)");
      await tester.tap(xtzRow.first);

      await tester.pumpAndSettle(Duration(seconds: 2));

      await tester.tap(find.text("SEND"));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'tz1Td5qwQxz5mDZiwk7TsRGhDU2HBvXgULip');
      await tester.pumpAndSettle(Duration(seconds: 1));
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle(Duration(seconds: 10));

      await tester.tap(find.textContaining("Max"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("REVIEW"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("SEND"));
      await tester.pumpAndSettle(Duration(seconds: 10));

      //Expect to comeback to wallet detail after sending successfully
      expect(find.text("SEND"), findsOneWidget);
      expect(find.text("RECEIVE"), findsOneWidget);
    });
  });
}
