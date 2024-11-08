import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/exhibition_item.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ExploreExhibition extends StatefulWidget {
  final String? searchText;
  final Map<FilterType, FilterValue> filters;
  final SortBy sortBy;

  const ExploreExhibition(
      {required this.filters,
      required this.sortBy,
      this.searchText,
      super.key});

  @override
  State<ExploreExhibition> createState() => ExploreExhibitionState();

  bool isEqual(Object other) =>
      other is ExploreExhibition &&
      other.searchText == searchText &&
      other.filters == filters &&
      other.sortBy == sortBy;
}

class ExploreExhibitionState extends State<ExploreExhibition> {
  List<Exhibition>? _exhibitions;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    unawaited(_fetchExhibitions(context));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExploreExhibition oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_fetchExhibitions(context));
    scrollToTop();
  }

  void scrollToTop() {
    unawaited(_scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ));
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'no_exhibition_found'.tr(),
        style: theme.textTheme.ppMori400White14,
      ),
    );
  }

  Widget _exhibitionView(BuildContext context, List<Exhibition> exhibitions) =>
      ListExhibitionView(
          scrollController: _scrollController,
          exhibitions: exhibitions,
          padding: const EdgeInsets.only(bottom: 100));

  @override
  Widget build(BuildContext context) {
    if (_exhibitions == null) {
      return _loadingView(context);
    } else if (_exhibitions!.isEmpty) {
      return _emptyView(context);
    } else {
      return _exhibitionView(context, _exhibitions!);
    }
  }

  Future<List<Exhibition>> _addSourceExhibitionIfNeeded(
    List<Exhibition> exhibitions,
  ) async {
    final isExistingSourceExhibition =
        exhibitions.any((exhibition) => exhibition.id == SOURCE_EXHIBITION_ID);

    final shouldAddSourceExhibition = !isExistingSourceExhibition &&
        widget.filters.isEmpty &&
        (widget.searchText == null || widget.searchText!.isEmpty) &&
        widget.sortBy == SortBy.openAt;

    if (!shouldAddSourceExhibition) {
      return exhibitions;
    }
    final sourceExhibition =
        await injector<FeralFileService>().getSourceExhibition();
    final exhibitionAfterSource = exhibitions.firstWhereOrNull((exhibition) =>
        exhibition.exhibitionStartAt
            .isBefore(sourceExhibition.exhibitionStartAt));
    if (exhibitionAfterSource == null) {
      return exhibitions..insert(exhibitions.length - 1, sourceExhibition);
    } else {
      final index = exhibitions.indexOf(exhibitionAfterSource);
      return exhibitions..insert(index, sourceExhibition);
    }
  }

  Future<List<Exhibition>> _fetchExhibitions(BuildContext context,
      {int offset = 0, int pageSize = 50}) async {
    final sortBy = widget.sortBy;
    final exhibitions = await injector<FeralFileService>().getAllExhibitions(
      keywork: widget.searchText ?? '',
      offset: offset,
      limit: pageSize,
      sortBy: sortBy.queryParam,
      sortOrder: sortBy.sortOrder.queryParam,
      filters: widget.filters,
    );
    final exhibitionsWithSource =
        await _addSourceExhibitionIfNeeded(exhibitions);
    setState(() {
      _exhibitions = exhibitionsWithSource;
    });
    return exhibitionsWithSource;
  }
}

class ListExhibitionView extends StatefulWidget {
  final List<Exhibition> exhibitions;
  final ScrollController? scrollController;
  final bool isScrollable;
  final EdgeInsets padding;

  const ListExhibitionView({
    required this.exhibitions,
    this.scrollController,
    super.key,
    this.isScrollable = true,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<ListExhibitionView> createState() => _ListExhibitionViewState();
}

class _ListExhibitionViewState extends State<ListExhibitionView> {
  static const _padding = 12.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final divider =
        addDivider(height: 40, color: AppColor.auQuickSilver, thickness: 0.5);
    return CustomScrollView(
      controller: _scrollController,
      shrinkWrap: true,
      physics: widget.isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exhibition = widget.exhibitions[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _padding),
                      child: ExhibitionCard(
                        exhibition: exhibition,
                        viewableExhibitions: widget.exhibitions,
                        horizontalMargin: _padding,
                      ),
                    ),
                    if (index != widget.exhibitions.length - 1) divider,
                  ],
                );
              },
              childCount: widget.exhibitions.length,
            ),
          ),
        )
      ],
    );
  }
}
