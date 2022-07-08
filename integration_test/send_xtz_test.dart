import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;
import 'test_util.dart';

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

Future<void> onboardingSteps(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(Duration(seconds: 5));
  await tester.pumpWidget(AutonomyApp());

  await tester.pumpAndSettle(Duration(seconds: 3));

  expect(find.text('AUTONOMY'), findsOneWidget);

  await injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);

  final Finder startButton = find.text("START");
  if (startButton.evaluate().isNotEmpty) {
    // Fresh start
    await tester.tap(startButton);

    await tester.pumpAndSettle();

    final Finder continueButton = find.text("CONTINUE");
    await tester.tap(continueButton);

    await tester.pumpAndSettle();

    final Finder notNowButton = find.text("NOT NOW");
    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton);
      await tester.pumpAndSettle();
    }

    final Finder createAccountButton = find.text("No");
    await tester.tap(createAccountButton);

    await tester.pumpAndSettle(Duration(seconds: 4));
    await tester.pumpAndSettle(Duration(seconds: 1));

    final Finder continueButton2 = find.text("CONTINUE");
    await tester.tap(continueButton2);

    await tester.pumpAndSettle();

    final Finder skipButton = find.text("SKIP");
    await tester.tap(skipButton);

    await tester.pumpAndSettle();

    final Finder continueButton3 = find.text("CONTINUE");
    await tester.tap(continueButton3);

    await tester.pumpAndSettle(Duration(seconds: 2));

    expect(find.text("Collection"), findsOneWidget);
  } else {
    //Restore
    final Finder restoreButton = find.text("RESTORE");
    await tester.tap(restoreButton);

    await tester.pumpAndSettle(Duration(seconds: 3));

    final Finder notNowButton = find.text("NOT NOW");
    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton);
      await tester.pumpAndSettle();
    }
  }
}
