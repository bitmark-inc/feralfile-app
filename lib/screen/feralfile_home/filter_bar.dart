import 'package:autonomy_flutter/screen/feralfile_home/filter_expanded_item.dart';
import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  final Map<FilterType, List<FilterValue>> filters;
  final Function(FilterType, FilterValue) onFilterSelected;
  final Function(FilterType) onFilterCleared;

  const FilterBar(
      {required this.filters,
      required this.onFilterSelected,
      required this.onFilterCleared,
      super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  Map<FilterType, FilterValue> _selectedFilters = {};
  Map<FilterType, GlobalKey<FilterExpanandedItemState>> _globalKeys = {};

  @override
  void initState() {
    super.initState();
    _generateGlobalKeys();
  }

  void _onFilterSelected(FilterType type, FilterValue value) {
    setState(() {
      _selectedFilters[type] = value;
    });
    widget.onFilterSelected(type, value);
  }

  void _generateGlobalKeys() {
    for (final entry in widget.filters.entries) {
      final key = GlobalKey<FilterExpanandedItemState>(
          debugLabel: 'filter_${entry.key.name}');
      _globalKeys[entry.key] = key;
    }
  }

  void _onFilterCleared(FilterType type) {
    setState(() {
      _selectedFilters.remove(type);
    });
    widget.onFilterCleared(type);
  }

  Widget _filterItem(FilterType type, List<FilterValue> values) {
    return FilterExpanandedItem(
      key: _globalKeys[type],
      type: type.name,
      values: values.map((e) => e.name).toList(),
      selectedIndex: _selectedFilters[type] != null
          ? values.indexOf(_selectedFilters[type]!)
          : null,
      onFilterSelected: (index) => _onFilterSelected(type, values[index]),
      onFilterCleared: () => _onFilterCleared(type),
      onFilterExpanded: () {
        for (final entry in _globalKeys.entries) {
          if (entry.key != type) {
            final state = entry.value.currentState;
            state?.collapse();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in widget.filters.entries)
            Container(
              padding: const EdgeInsets.all(1.0),
              child: _filterItem(entry.key, entry.value),
            ),
        ],
      ),
    );
  }
}

enum FilterType {
  type,
  chain,
  medium;

  String get name {
    switch (this) {
      case FilterType.type:
        return 'Type';
      case FilterType.chain:
        return 'Chain';
      case FilterType.medium:
        return 'Medium';
    }
  }

  String get queryParam {
    switch (this) {
      case FilterType.type:
        return 'type';
      case FilterType.chain:
        return 'chain';
      case FilterType.medium:
        return 'medium';
    }
  }
}

enum FilterValue {
  // artwork type
  edition,
  series,
  oneofone,

  // exhibition type
  solo,
  group,

  // chain
  ethereum,
  tezos,

  // medium
  image,
  video,
  software,
  pdf,
  audio,
  threeD,
  animatedGif,
  text;

  String get name {
    switch (this) {
      case FilterValue.edition:
        return 'Edition';
      case FilterValue.series:
        return 'Series';
      case FilterValue.oneofone:
        return 'One of One';
      case FilterValue.solo:
        return 'Solo';
      case FilterValue.group:
        return 'Group';
      case FilterValue.ethereum:
        return 'Ethereum';
      case FilterValue.tezos:
        return 'Tezos';
      case FilterValue.image:
        return 'Image';
      case FilterValue.video:
        return 'Video';
      case FilterValue.software:
        return 'Software';
      case FilterValue.pdf:
        return 'PDF';
      case FilterValue.audio:
        return 'Audio';
      case FilterValue.threeD:
        return '3D';
      case FilterValue.animatedGif:
        return 'Animated GIF';
      case FilterValue.text:
        return 'Text';
    }
  }

  String get queryParam {
    switch (this) {
      case FilterValue.edition:
        return 'multi';
      case FilterValue.series:
        return 'multi_unique';
      case FilterValue.oneofone:
        return 'single';
      case FilterValue.solo:
        return 'solo';
      case FilterValue.group:
        return 'group';
      case FilterValue.ethereum:
        return 'ethereum';
      case FilterValue.tezos:
        return 'tezos';
      case FilterValue.image:
        return 'image';
      case FilterValue.video:
        return 'video';
      case FilterValue.software:
        return 'software';
      case FilterValue.pdf:
        return 'pdf';
      case FilterValue.audio:
        return 'audio';
      case FilterValue.threeD:
        return '3d';
      case FilterValue.animatedGif:
        return 'animated gif';
      case FilterValue.text:
        return 'txt';
    }
  }
}

enum SortBy {
  firstExhibitionJoinedAt,
  createdAt,
  openAt,
  alias,
  title;

  String get queryParam {
    switch (this) {
      case SortBy.firstExhibitionJoinedAt:
        return 'firstExhibitionJoinedAt';
      case SortBy.createdAt:
        return 'createdAt';
      case SortBy.openAt:
        return 'openAt';
      case SortBy.title:
        return 'title';
      case SortBy.alias:
        return 'alias';
    }
  }

  String get name {
    switch (this) {
      case SortBy.firstExhibitionJoinedAt:
      case SortBy.createdAt:
      case SortBy.openAt:
        return 'Recent';
      case SortBy.alias:
      case SortBy.title:
        return 'A to Z';
    }
  }

  SortOrder get sortOrder {
    switch (this) {
      case SortBy.firstExhibitionJoinedAt:
      case SortBy.createdAt:
      case SortBy.openAt:
        return SortOrder.desc;
      case SortBy.title:
      case SortBy.alias:
        return SortOrder.asc;
    }
  }
}

enum SortOrder {
  asc,
  desc;

  String get queryParam {
    switch (this) {
      case SortOrder.asc:
        return 'ASC';
      case SortOrder.desc:
      default:
        return 'DESC';
    }
  }
}
