import 'package:autonomy_flutter/screen/feralfile_home/filter_expanded_item.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase filterExpandedItem() {
  return WidgetbookUseCase(
    name: 'Filter Expanded Item',
    builder: (context) => FilterExpanandedItem(
      type: 'Filter Type',
      values: ['Value 1', 'Value 2', 'Value 3'],
      selectedIndex: 0,
      onFilterSelected: (index) {},
      onFilterCleared: () {},
    ),
  );
}
