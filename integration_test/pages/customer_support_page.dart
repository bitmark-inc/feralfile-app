import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../commons/test_util.dart';
import '../pages/onBoarding_page.dart';


Finder supportIcon = find.byKey(const Key("customerSupport"));
Finder howCanWeHelp = find.text("How can we help?");
Finder requestAFeature = find.text("Request a feature");
Finder reportABug= find.text("Report a bug");
Finder shareFeedback = find.text("Share feedback");
Finder somethingElse = find.text("Something else?");
Finder resources = find.text("RESOURCES");
Finder supportHistory = find.text("Support history");
Finder back = find.text("back");

Future<void> testSupportPage(WidgetTester tester, String feature, bool isFirst) async{
  if(isFirst) {
    await initAppAutonomy(tester);
  }

  await launchAutonomy(tester);


  if(isFirst) {
    await onboardingSteps(tester);
  }

  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tester.tap(supportIcon);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  expect(howCanWeHelp, findsOneWidget);
  expect(findFeature(feature), findsOneWidget);
}

Finder findFeature(String feature){
  return find.text(feature);
}