import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase seriesView() {
  return WidgetbookUseCase(
    name: 'Series View',
    builder: (context) => const SeriesView(
      series: [],
      userCollections: [],
      exploreBar: Text('Explore'),
      header: Text('Series'),
    ),
  );
}
