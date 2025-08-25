import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_ff_series.dart';

WidgetbookUseCase seriesView() {
  return WidgetbookUseCase(
    name: 'Series View',
    builder: (context) => SeriesView(
      series: MockFFSeriesData.listSeries,
      userCollections: const [],
      exploreBar: const SizedBox(),
      header: const SizedBox.shrink(),
    ),
  );
}
