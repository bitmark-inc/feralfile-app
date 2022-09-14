//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//


import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../commons/test_util.dart';
import '../pages/onBoarding_page.dart';
import '../pages/setting_page.dart';
import '../pages/static_test_page.dart';

void main() async{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("static page test", (){
    testWidgets("Release notes", (tester) async{

      await initAppAutonomy(tester);
      await launchAutonomy(tester);
      await onboardingSteps(tester);
      await addDelay(3000);


      await settingScrollToFinder(tester, releaseNotes, Scrollable);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(releaseNotes, findsOneWidget);

      String versionStr = getVersion(versionFinder); //this should return "_version_"
      print(versionStr);

      await tester.tap(releaseNotes);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(find.text("What’s new?"), findsOneWidget);
      expect(find.text("CLOSE"),findsOneWidget);


      String releaseNotesStr = getStringFromMarkdown(mdObj, 0, versionStr.length+2); //this should return: "[_version_]"

      expect(releaseNotesStr=="[$versionStr]", isTrue);
    });

    testWidgets("EULA", (tester) async{
      await launchAutonomy(tester);
      await settingScrollToFinder(tester, eula, Scrollable);

      expect(eula, findsOneWidget);

      await tester.tap(eula);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(backButton, findsOneWidget);
      expect(getMarkdownData(mdGithub).contains("Autonomy End User License Agreement"), isTrue);

    });

    testWidgets("Privacy Policy", (tester) async{
      await launchAutonomy(tester);
      await settingScrollToFinder(tester, privacyPolicy, Scrollable);

      expect(privacyPolicy, findsOneWidget);

      await tester.tap(privacyPolicy);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(backButton, findsOneWidget);

      expect(getMarkdownData(mdGithub).contains("Autonomy Privacy Policy"), isTrue);
    });
  });
}