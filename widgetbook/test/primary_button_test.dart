import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testWidgets('PrimaryButton golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrimaryButton(
                text: 'Default Button',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Disabled Button',
                enabled: false,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Loading Button',
                isProcessing: true,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Custom Color Button',
                color: Colors.green,
                textColor: Colors.white,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Custom Border Button',
                borderColor: Colors.blue,
                borderRadius: 16,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('primary_button_golden.png'),
    );
  });
}
