import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  // Initialize Golden Toolkit and load fonts
  setUpAll(() async {
    await loadAppFonts();
  });

  group("Test Components", () {
    testGoldens("Loading Indicator", (WidgetTester tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          "Loading Widget",
          LoadingWidget(),
        );
      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
      );

      await screenMatchesGolden(tester, "loading_widget");
    });

    testGoldens("FF Cast Button", (WidgetTester tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          "FF Cast Button",
          FFCastButton(
            displayKey: "Display key",
            type: "Type",
            text: "Text",
            shouldCheckSubscription: true,
            onTap: () {},
          ),
        );
      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
      );

      await screenMatchesGolden(tester, "ff_cast_button");
    });
  });
}
