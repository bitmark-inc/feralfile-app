import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase listExhibitionView() {
  return WidgetbookUseCase(
    name: 'List Exhibition View',
    builder: (context) => const ListExhibitionView(
      exhibitions: [],
      exploreBar: Text('Explore'),
      header: Text('Exhibitions'),
    ),
  );
}
