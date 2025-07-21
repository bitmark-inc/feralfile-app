import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/components/mock_wrapper.dart';

final WidgetbookComponent settingsPageComponent = WidgetbookComponent(
  name: 'SettingsPage',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) => const MockWrapper(
        child: SettingsPage(),
      ),
    ),
  ],
);
