import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase featuredWorkView() {
  return WidgetbookUseCase(
    name: 'Featured Work View',
    builder: (context) => const FeaturedWorkView(
      tokenIDs: ['mock_token_1', 'mock_token_2'],
      header: Text('Featured Works'),
    ),
  );
}
