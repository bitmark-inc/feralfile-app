

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../commons/test_util.dart';
import '../pages/onBoarding_page.dart';
import '../pages/setting_page.dart';

void main() async{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("static page test", (){
    testWidgets("Release notes", (tester) async{

      await initAppAutonomy(tester);
      await launchAutonomy(tester);
      await onboardingSteps(tester);
      await addDelay(3000);

      final releaseNotes = find.text("Release notes");
      await settingScrollToFinder(tester, releaseNotes, Scrollable);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);
      expect(releaseNotes, findsOneWidget);

      Finder versionFinder = find.byKey(const Key("version"));
      Text versionWidget = versionFinder.evaluate().single.widget as Text;
      String versionFullStr = versionWidget.data??"";
      print(versionFullStr);
      int endIndex = versionFullStr.indexOf("(");
      String? versionStr = versionFullStr.substring(8,endIndex);
      print(versionStr);

      await tester.tap(releaseNotes);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(find.text("What’s new?"), findsOneWidget);
      expect(find.text("CLOSE"),findsOneWidget);

      Finder releaseNotesFinder = find.byType(Markdown);
      Markdown releaseNotesMD = releaseNotesFinder.evaluate().single.widget as Markdown;
      String releaseNotesStr = releaseNotesMD.data.substring(0,versionStr.length+2);

      expect(releaseNotesStr=="[$versionStr]", isTrue);
    });

    testWidgets("EULA", (tester) async{
      await launchAutonomy(tester);
      Finder eula = find.text("EULA");
      await settingScrollToFinder(tester, eula, Scrollable);
      expect(eula, findsOneWidget);

      await tester.tap(eula);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(backButton, findsOneWidget);

      Markdown md = find.byKey(const Key("githubMarkdown")).evaluate().single.widget as Markdown;
      expect(md.data.contains("Autonomy End User License Agreement"), isTrue);
    });

    testWidgets("Privacy Policy", (tester) async{
      await launchAutonomy(tester);
      Finder privacyPolicy = find.text("Privacy Policy");
      await settingScrollToFinder(tester, privacyPolicy, Scrollable);
      expect(privacyPolicy, findsOneWidget);

      await tester.tap(privacyPolicy);

      await addDelay(5000);
      await tester.pump();
      await tester.pump();
      await addDelay(5000);

      expect(backButton, findsOneWidget);

      Markdown md = find.byKey(const Key("githubMarkdown")).evaluate().single.widget as Markdown;
      expect(md.data.contains("Autonomy Privacy Policy"), isTrue);
    });
  });
}