import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/home/view/home_mobile_controller.dart';
import 'package:autonomy_flutter/widgetbook/components/mock_wrapper.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mobile_controller_test_helper.dart';

void main() {
  setUpAll(() async {
    await MobileControllerTestHelper.setupMockData();
    await EasyLocalization.ensureInitialized();
  });

  group('MobileControllerHomePage', () {
    testWidgets('Default View', (WidgetTester tester) async {
      debugPrint('Starting MobileControllerHomePage test...');

      // Set screen size to 393x852
      await tester.binding.setSurfaceSize(const Size(393, 852));

      await tester.runAsync(() async {
        final testWidget =
            MobileControllerTestHelper.createMobileControllerTestWidget();

        debugPrint('Pumping widget...');
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();
      });

      final pageFinder = find.byType(MobileControllerHomePage);
      expect(pageFinder, findsOneWidget);

      // Verify that the widget renders without crashing
      expect(pageFinder, findsOneWidget);
    });

    testWidgets('With Initial Page Index 1', (WidgetTester tester) async {
      debugPrint('Starting MobileControllerHomePage test with page index 1...');

      // Set screen size to 393x852
      await tester.binding.setSurfaceSize(const Size(393, 852));

      await tester.runAsync(() async {
        final testWidget =
            MobileControllerTestHelper.createMobileControllerTestWidget(
          initialPageIndex: 1,
        );

        debugPrint('Pumping widget...');
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();
      });

      final pageFinder = find.byType(MobileControllerHomePage);
      expect(pageFinder, findsOneWidget);

      // Verify that the widget renders without crashing
      expect(pageFinder, findsOneWidget);
    });

    testWidgets('Dark Theme', (WidgetTester tester) async {
      debugPrint('Starting MobileControllerHomePage test with dark theme...');

      // Set screen size to 393x852
      await tester.binding.setSurfaceSize(const Size(393, 852));

      await tester.runAsync(() async {
        final testWidget =
            MobileControllerTestHelper.createMobileControllerTestWidget(
          theme: ThemeData.dark(),
        );

        debugPrint('Pumping widget...');
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();
      });

      final pageFinder = find.byType(MobileControllerHomePage);
      expect(pageFinder, findsOneWidget);

      // Verify that the widget renders without crashing
      expect(pageFinder, findsOneWidget);
    });

    testWidgets('Light Theme', (WidgetTester tester) async {
      debugPrint('Starting MobileControllerHomePage test with light theme...');

      // Set screen size to 393x852
      await tester.binding.setSurfaceSize(const Size(393, 852));

      await tester.runAsync(() async {
        final testWidget =
            MobileControllerTestHelper.createMobileControllerTestWidget(
          theme: ThemeData.light(),
        );

        debugPrint('Pumping widget...');
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();
      });

      final pageFinder = find.byType(MobileControllerHomePage);
      expect(pageFinder, findsOneWidget);

      // Verify that the widget renders without crashing
      expect(pageFinder, findsOneWidget);
    });
  });
}
