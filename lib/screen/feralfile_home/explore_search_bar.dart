import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/sort_bar.dart';
import 'package:autonomy_flutter/util/log.dart';
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
  final TextEditingController _controller = TextEditingController();
  final Map<FilterType, FilterValue> _filters = {};
  late SortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _sortBy =
        widget.tab.getDefaultSortBy(isSearching: _controller.text.isNotEmpty);
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
    final canCancel = _searchText != null && _searchText!.isNotEmpty;
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
              onChanged: (value) {},
              minSearchLength: 3,
              minSearchLengthWhenPressEnter: 2,
            ),
            onCancel: canCancel
                ? () {
                    _controller.clear();
                    _onSearch(null);
                  }
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterBar(
                filters: widget.tab.getFilterBy(),
                onFilterSelected: (type, value) {
                  log.info('Filter selected: $type, $value');
                  setState(() {
                    _filters[type] = value;
                  });
                },
                onFilterCleared: (type) {
                  log.info('Filter cleared: $type');
                  setState(() {
                    _filters.remove(type);
                  });
                },
              ),
              const Spacer(),
              SortBar(
                sortBys: widget.tab.getSortBy(
                    isSearching:
                        _searchText != null && _searchText!.isNotEmpty),
                defaultSortBy: widget.tab.getDefaultSortBy(
                    isSearching:
                        _searchText != null && _searchText!.isNotEmpty),
                onSortSelected: (sortBy) {
                  log.info('Sort selected: $sortBy');
                  setState(() {
                    _sortBy = sortBy;
                  });
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(child: _buildChild())
      ],
    );
  }
}
