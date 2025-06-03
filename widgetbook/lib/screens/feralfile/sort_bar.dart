import 'package:autonomy_flutter/screen/feralfile_home/sort_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase sortBar() {
  return WidgetbookUseCase(
    name: 'Sort Bar',
    builder: (context) => SortBar(
      sortBys: [SortBy.createdAt, SortBy.title],
      defaultSortBy: SortBy.createdAt,
      onSortSelected: (sortBy) {},
    ),
  );
}
