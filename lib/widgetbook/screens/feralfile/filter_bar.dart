import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase filterBar() {
  return WidgetbookUseCase(
    name: 'Filter Bar',
    builder: (context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FilterBar(
                filters: {
                  FilterType.type: [FilterValue.edition, FilterValue.series],
                  FilterType.chain: [FilterValue.ethereum, FilterValue.tezos],
                  FilterType.medium: [FilterValue.image, FilterValue.video],
                },
                onFilterSelected: (type, value) {},
                onFilterCleared: (type) {},
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
