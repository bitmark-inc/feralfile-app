import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/feralfile_home/explore_search_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
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
  final Widget? header;

  const ExploreExhibition({super.key, this.header});

  @override
  State<ExploreExhibition> createState() => ExploreExhibitionState();
}

class ExploreExhibitionState extends State<ExploreExhibition> {
  List<Exhibition>? _exhibitions;
  late ScrollController _scrollController;
  late String? _searchText;
  late Map<FilterType, FilterValue> _filters;
  late SortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchText = null;
    _filters = {};
    _sortBy = FeralfileHomeTab.exhibitions.getDefaultSortBy();
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

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'no_exhibition_found'.tr(),
        style: theme.textTheme.ppMori400White14,
      ),
    );
  }

  Widget _getExploreBar(BuildContext context) => ExploreBar(
        key: const ValueKey(FeralfileHomeTab.exhibitions),
        onUpdate: (searchText, filters, sortBy) async {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            _searchText = searchText;
            _filters = filters;
            _sortBy = sortBy;
            await _fetchExhibitions(context);
          });
        },
        tab: FeralfileHomeTab.exhibitions,
      );

  Widget _exhibitionView(BuildContext context, List<Exhibition>? exhibitions) =>
      ListExhibitionView(
        scrollController: _scrollController,
        exhibitions: exhibitions,
        padding: const EdgeInsets.only(bottom: 100),
        exploreBar: _getExploreBar(context),
        header: widget.header,
        emptyWidget: _emptyView(context),
      );

  @override
  Widget build(BuildContext context) => _exhibitionView(context, _exhibitions);

  Future<List<Exhibition>> _addSourceExhibitionIfNeeded(
    List<Exhibition> exhibitions,
  ) async {
    final isExistingSourceExhibition =
        exhibitions.any((exhibition) => exhibition.id == SOURCE_EXHIBITION_ID);

    final shouldAddSourceExhibition = !isExistingSourceExhibition &&
        _filters.isEmpty &&
        (_searchText == null || _searchText!.isEmpty) &&
        _sortBy == SortBy.openAt;

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
    final sortBy = _sortBy;
    final exhibitions = await injector<FeralFileService>().getAllExhibitions(
      keywork: _searchText ?? '',
      offset: offset,
      limit: pageSize,
      sortBy: sortBy.queryParam,
      sortOrder: sortBy.sortOrder.queryParam,
      filters: _filters,
    );
    final exhibitionsWithSource =
        await _addSourceExhibitionIfNeeded(exhibitions);
    if (mounted) {
      setState(() {
        _exhibitions = exhibitionsWithSource;
      });
    }
    return exhibitionsWithSource;
  }
}

class ListExhibitionView extends StatefulWidget {
  final List<Exhibition>? exhibitions;
  final ScrollController? scrollController;
  final bool isScrollable;
  final EdgeInsets padding;
  final Widget? exploreBar;
  final Widget? header;
  final Widget emptyWidget;

  const ListExhibitionView({
    required this.exhibitions,
    this.scrollController,
    super.key,
    this.isScrollable = true,
    this.padding = const EdgeInsets.all(0),
    this.exploreBar,
    this.header,
    this.emptyWidget = const SizedBox.shrink(),
  });

  @override
  State<ListExhibitionView> createState() => _ListExhibitionViewState();
}

class _ListExhibitionViewState extends State<ListExhibitionView> {
  static const _padding = 15.0;
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
        if (widget.exploreBar != null || widget.header != null) ...[
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 32),
          ),
          SliverToBoxAdapter(
            child: widget.header ?? const SizedBox.shrink(),
          ),
          SliverToBoxAdapter(
            child: widget.exploreBar ?? const SizedBox.shrink(),
          ),
        ],
        if (widget.exhibitions == null) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 150),
              child: Center(child: LoadingWidget()),
            ),
          ),
        ] else if (widget.exhibitions!.isEmpty) ...[
          SliverToBoxAdapter(
            child: widget.emptyWidget,
          ),
        ] else ...[
          SliverPadding(
            padding: widget.padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exhibition = widget.exhibitions![index];
                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: _padding),
                        child: ExhibitionCard(
                          exhibition: exhibition,
                          viewableExhibitions: widget.exhibitions!,
                          horizontalMargin: _padding,
                        ),
                      ),
                      if (index != widget.exhibitions!.length - 1) divider,
                    ],
                  );
                },
                childCount: widget.exhibitions!.length,
              ),
            ),
          )
        ],
      ],
    );
  }
}
