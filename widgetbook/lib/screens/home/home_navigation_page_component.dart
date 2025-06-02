import 'package:autonomy_flutter/screen/home/home_navigation_page.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/components/mock_wrapper.dart';

final WidgetbookComponent homeNavigationPageComponent = WidgetbookComponent(
  name: 'HomeNavigationPage',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) => const MockWrapper(
        child: HomeNavigationPage(),
      ),
    ),
  ],
);
