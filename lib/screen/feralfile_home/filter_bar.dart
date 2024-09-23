import 'package:autonomy_flutter/screen/feralfile_home/filter_expanded_item.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_home.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final Map<FilterType, FilterValue> _selectedFilters = {};
  final Map<FilterType, GlobalKey<FilterExpanandedItemState>> _globalKeys = {};

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

  Widget _filterItem(FilterType type, List<FilterValue> values) => FilterItem(
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

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in widget.filters.entries)
            Container(
              padding: const EdgeInsets.all(1),
              child: _filterItem(entry.key, entry.value),
            ),
        ],
      );
}

enum FilterType {
  type,
  chain,
  medium;

  String get name {
    switch (this) {
      case FilterType.type:
        return 'type'.tr();
      case FilterType.chain:
        return 'chain'.tr();
      case FilterType.medium:
        return 'medium'.tr();
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
        return 'edition'.tr();
      case FilterValue.series:
        return 'series'.tr();
      case FilterValue.oneofone:
        return '1_of_1'.tr();
      case FilterValue.solo:
        return 'solo'.tr();
      case FilterValue.group:
        return 'group'.tr();
      case FilterValue.ethereum:
        return 'ethereum'.tr();
      case FilterValue.tezos:
        return 'tezos'.tr();
      case FilterValue.image:
        return 'image'.tr();
      case FilterValue.video:
        return 'video'.tr();
      case FilterValue.software:
        return 'software'.tr();
      case FilterValue.pdf:
        return 'pdf'.tr();
      case FilterValue.audio:
        return 'audio'.tr();
      case FilterValue.threeD:
        return '3d'.tr();
      case FilterValue.animatedGif:
        return 'animated_gif'.tr();
      case FilterValue.text:
        return 'txt'.tr();
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
  relevance,
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
      case SortBy.relevance:
        return 'relevance';
    }
  }

  String get name {
    switch (this) {
      case SortBy.firstExhibitionJoinedAt:
      case SortBy.createdAt:
      case SortBy.openAt:
        return 'recent'.tr();
      case SortBy.alias:
      case SortBy.title:
        return 'a_to_z'.tr();
      case SortBy.relevance:
        return 'relevance'.tr();
    }
  }

  SortOrder get sortOrder {
    switch (this) {
      case SortBy.firstExhibitionJoinedAt:
      case SortBy.createdAt:
      case SortBy.openAt:
      case SortBy.relevance:
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
