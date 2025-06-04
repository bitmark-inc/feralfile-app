import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

final primaryButtonComponent = WidgetbookComponent(
  name: 'PrimaryButton',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: useCaseDefaultPrimaryButton,
    ),
    WidgetbookUseCase(
      name: 'Disabled',
      builder: useCaseDisabledPrimaryButton,
    ),
    WidgetbookUseCase(
      name: 'Loading',
      builder: useCaseLoadingPrimaryButton,
    ),
    WidgetbookUseCase(
      name: 'Custom Style',
      builder: useCaseCustomStylePrimaryButton,
    ),
  ],
);

Widget useCaseDefaultPrimaryButton(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              text: context.knobs.string(
                label: 'Text',
                description: 'The text to display on the button',
                initialValue: 'Hello World!',
              ),
              enabled: context.knobs.boolean(
                label: 'Enabled',
                description: 'Whether the button is enabled',
                initialValue: true,
              ),
              isProcessing: context.knobs.boolean(
                label: 'Is Processing',
                description: 'Whether to show loading indicator',
                initialValue: false,
              ),
              width: context.knobs.doubleOrNull.input(
                label: 'Width',
                description: 'The width of the button (null for auto)',
                initialValue: null,
              ),
              color: context.knobs.colorOrNull(
                label: 'Color',
                description: 'The background color of the button',
                initialValue: null,
              ),
              textColor: context.knobs.colorOrNull(
                label: 'Text Color',
                description: 'The color of the text',
                initialValue: null,
              ),
              borderColor: context.knobs.colorOrNull(
                label: 'Border Color',
                description: 'The color of the border',
                initialValue: null,
              ),
              borderRadius: context.knobs.double.input(
                label: 'Border Radius',
                description: 'The border radius of the button',
                initialValue: 32,
              ),
              onTap: () {
                // Handle tap event
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget useCaseDisabledPrimaryButton(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              text: 'Disabled Button',
              enabled: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

Widget useCaseLoadingPrimaryButton(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              text: 'Loading Button',
              isProcessing: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

Widget useCaseCustomStylePrimaryButton(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              text: 'Custom Style Button',
              color: Colors.green,
              textColor: Colors.white,
              borderColor: Colors.blue,
              borderRadius: 16,
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
