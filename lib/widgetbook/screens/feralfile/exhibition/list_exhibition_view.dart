import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_exhibition.dart';

WidgetbookUseCase listExhibitionView() {
  return WidgetbookUseCase(
    name: 'List Exhibition View',
    builder: (context) => ListExhibitionView(
      exhibitions: MockExhibitionData.listExhibition,
      exploreBar: SizedBox(),
      header: SizedBox.shrink(),
    ),
  );
}
