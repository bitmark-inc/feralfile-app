import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/sort_bar.dart';
import 'package:autonomy_flutter/view/search_bar.dart';
import 'package:flutter/material.dart';

class ExploreBar extends StatefulWidget {
  final Widget Function(
    String?,
    Map<FilterType, FilterValue> filters,
    SortBy sortBy,
  ) childBuilder;
  final FeralfileHomeTab tab;

  const ExploreBar(
      {required this.childBuilder,
      super.key,
      this.tab = FeralfileHomeTab.artworks});

  @override
  State<ExploreBar> createState() => _ExploreBarState();
}

class _ExploreBarState extends State<ExploreBar> {
  String? _searchText;
  TextEditingController _controller = TextEditingController();
  Map<FilterType, FilterValue> _filters = {};
  late SortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.tab.getDefaultSortBy();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildChild() => widget.childBuilder(_searchText, _filters, _sortBy);

  void _onSearch(String? value) {
    setState(() {
      _searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ActionBar(
            searchBar: AuSearchBar(
              controller: _controller,
              onSearch: (value) {
                _onSearch(value);
              },
              onClear: (value) {
                _onSearch(null);
              },
              onChanged: (value) {
                // _onSearch(value);
              },
            ),
            onCancel: () {
              _controller.clear();
              _onSearch(null);
            },
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterBar(
                filters: widget.tab.getFilterBy(),
                onFilterSelected: (type, value) {
                  print('Filter selected: $type, $value');
                  setState(() {
                    _filters[type] = value;
                  });
                },
                onFilterCleared: (type) {
                  print('Filter cleared: $type');
                  setState(() {
                    _filters.remove(type);
                  });
                },
              ),
              const Spacer(),
              SortBar(
                sortBys: widget.tab.getSortBy(),
                defaultSortBy: widget.tab.getDefaultSortBy(),
                onSortSelected: (sortBy) {
                  print('Sort selected: $sortBy');
                  setState(() {
                    _sortBy = sortBy;
                  });
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
            child: Column(
          children: [
            _buildChild(),
          ],
        ))
      ],
    );
  }
}
