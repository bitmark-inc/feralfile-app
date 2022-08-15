

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../commons/test_util.dart';
import '../pages/customer_support_page.dart';
import '../pages/onBoarding_page.dart';

void main() async{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Customer support", () {
    testWidgets("Request a feature", (tester) async{
      await testSupportPage(tester, "Request a feature", true);
    });
    testWidgets("Report a bug", (tester) async{
      await testSupportPage(tester, "Report a bug", false);
    });
    testWidgets("Share feedback", (tester) async{
      await testSupportPage(tester, "Share feedback", false);
    });
    testWidgets("Something else?", (tester) async{
      await testSupportPage(tester, "Something else?", false);
    });
  });
}