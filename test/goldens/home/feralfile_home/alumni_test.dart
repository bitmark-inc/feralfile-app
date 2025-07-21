import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_alumni_view.dart';
import 'package:autonomy_flutter/view/alumni_widget.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_alumni.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../cache_manager/cache_manager.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    MockInjector.setup();
    await EasyLocalization.ensureInitialized();

    final mockCacheManager = MockImageCacheManage();

    injector.unregister<CacheManager>();
    injector.registerLazySingleton<CacheManager>(
      () => mockCacheManager,
    );
  });

  group('Golden - AlumniCard', () {
    testGoldens('Alumni Avatar', (WidgetTester tester) async {
      debugPrint('Starting test...');
      await tester.runAsync(() async {
        final testWidget = MaterialApp(
            home: Scaffold(
          body: AlumniAvatar(
            url:
                "https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/c4b3b80e-ce44-4fac-db5d-5bd42cf3b900/m",
            // width: 200,
            // height: 200,
          ),
        ));

        debugPrint('Pumping widget...');
        await tester.pumpWidget(
          testWidget,
        );

        Element element = tester.element(find.byType(FFCacheNetworkImage));
        FFCacheNetworkImage cacheImage = element.widget as FFCacheNetworkImage;
        final provider = cacheImage.image;

        await precacheImage(provider, element);
        await tester.pumpAndSettle();
      });

      final imageFinder = find.byType(Scaffold);
      expect(imageFinder, findsOneWidget);

      await expectLater(
        imageFinder,
        matchesGoldenFile('goldens/alumni_avatar.png'),
        reason: 'Image should match golden file',
      );

      // screenMatchesGolden(tester, 'alumni_avatar');
    });

    testGoldens('Alumni Card', (WidgetTester tester) async {
      debugPrint('Starting Alumni Card test...');
      await tester.runAsync(() async {
        final testWidget = MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: AspectRatio(
              aspectRatio: 102.0 / 152,
              child: AlumniCard(
                alumni: MockAlumniData.driessensVerstappen,
              ),
            ),
          ),
        );

        debugPrint('Pumping widget...');
        await tester.pumpWidget(testWidget);

        Element element = tester.element(find.byType(FFCacheNetworkImage));
        FFCacheNetworkImage cacheImage = element.widget as FFCacheNetworkImage;
        final provider = cacheImage.image;

        await precacheImage(provider, element);

        await tester.pumpAndSettle();
      });

      final cardFinder = find.byType(Scaffold);
      expect(cardFinder, findsOneWidget);

      await expectLater(
        cardFinder,
        matchesGoldenFile('goldens/alumni_card.png'),
        reason: 'Alumni Card should match golden file',
      );
    });
  });
}
