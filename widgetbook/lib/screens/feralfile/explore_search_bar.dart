import 'package:autonomy_flutter/screen/feralfile_home/explore_search_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase exploreSearchBar() {
  return WidgetbookUseCase(
    name: 'Explore Search Bar',
    builder: (context) => ExploreBar(
      key: const ValueKey('explore'),
      onUpdate: (searchText, filters, sortBy) {},
      tab: FeralfileHomeTab.artworks,
    ),
  );
}
