import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_home.dart';
import 'package:flutter/material.dart';

class SortBar extends StatefulWidget {
  final SortBy defaultSortBy;
  final List<SortBy> sortBys;
  final Function(SortBy) onSortSelected;

  const SortBar(
      {required this.sortBys,
      required this.defaultSortBy,
      required this.onSortSelected,
      super.key});

  @override
  State<SortBar> createState() => _SortBarState();
}

class _SortBarState extends State<SortBar> {
  SortBy? _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.defaultSortBy;
  }

  @override
  void didUpdateWidget(covariant SortBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultSortBy != widget.defaultSortBy) {
      if (_selectedSortBy == oldWidget.defaultSortBy) {
        setState(() {
          _selectedSortBy = widget.defaultSortBy;
        });
      }
    }
  }

  void _onSortSelected(SortBy sortBy) {
    setState(() {
      _selectedSortBy = sortBy;
    });
    widget.onSortSelected(sortBy);
  }

  Widget _sortByItem(List<SortBy> values) => FilterItem(
        type: 'Sort By',
        values: values.map((e) => e.name).toList(),
        selectedIndex:
            _selectedSortBy != null ? values.indexOf(_selectedSortBy!) : null,
        onFilterSelected: (index) => _onSortSelected(values[index]),
        onFilterExpanded: () {},
      );

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            child: _sortByItem(widget.sortBys),
          ),
        ],
      );
}
