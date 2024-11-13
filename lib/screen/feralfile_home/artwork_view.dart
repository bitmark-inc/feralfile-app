import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/ff_series_tappable_thumbnail.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/user_collection_thumbnail.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/user_collection.dart';

class ExploreSeriesView extends StatefulWidget {
  final String? searchText;
  final Map<FilterType, FilterValue> filters;
  final SortBy sortBy;
  final int pageSize;

  const ExploreSeriesView(
      {required this.sortBy,
      this.searchText,
      this.pageSize = 20,
      super.key,
      this.filters = const {}});

  @override
  State<ExploreSeriesView> createState() => ExploreSeriesViewState();

  bool isEqual(Object other) =>
      other is ExploreSeriesView &&
      other.searchText == searchText &&
      other.filters == filters &&
      other.sortBy == sortBy &&
      other.pageSize == pageSize;
}

class ExploreSeriesViewState extends State<ExploreSeriesView> {
  List<FFSeries>? _series;
  List<UserCollection>? _userCollection;
  late Paging _paging;
  late ScrollController _scrollController;
  bool _isLoading = false;

  void scrollToTop() {
    unawaited(_scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ));
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels + 100 >
          _scrollController.position.maxScrollExtent) {
        unawaited(_loadMoreSeries(context,
            offset: _paging.offset + _paging.limit, pageSize: _paging.limit));
      }
    });
    _paging = Paging(offset: 0, limit: widget.pageSize, total: 0);
    unawaited(
        _fetchSeries(context, offset: _paging.offset, pageSize: _paging.limit));
  }

  @override
  void didUpdateWidget(covariant ExploreSeriesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_fetchSeries(context));
    scrollToTop();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child:
          Text('no_series_found'.tr(), style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _seriesView(BuildContext context, List<FFSeries> series,
          List<UserCollection> userCollection) =>
      SeriesView(
        series: series,
        userCollections: userCollection,
        scrollController: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
      );

  @override
  Widget build(BuildContext context) {
    if (_series == null) {
      return _loadingView(context);
    } else if (_series!.isEmpty) {
      return _emptyView(context);
    } else {
      return _seriesView(context, _series!, _userCollection ?? []);
    }
  }

  Future<List<FFSeries>> _fetchSeries(BuildContext context,
      {int offset = 0, int pageSize = 20}) async {
    if (_isLoading) {
      return [];
    }
    _isLoading = true;
    log.info('[Artwork View] fetch series with keyword: ${widget.searchText}');
    final res = await injector<FeralFileService>().exploreArtworks(
        sortBy: widget.sortBy.queryParam,
        sortOrder: widget.sortBy.sortOrder.queryParam,
        keyword: widget.searchText ?? '',
        offset: offset,
        limit: pageSize,
        filters: widget.filters);
    final series = res.result;
    final paging = res.paging!;
    setState(() {
      _series = series;

      _paging = paging;
    });
    _isLoading = false;
    return series;
  }

  Future<void> _loadMoreSeries(BuildContext context,
      {int offset = 0, int pageSize = 20}) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    final canLoadMore = _paging.offset < _paging.total;
    if (!canLoadMore) {
      _isLoading = false;
      return;
    }
    log.info(
        '[Artwork View] load more series with keyword: ${widget.searchText}');
    final res = await injector<FeralFileService>().exploreArtworks(
        keyword: widget.searchText ?? '',
        offset: offset,
        limit: pageSize,
        sortBy: widget.sortBy.queryParam,
        sortOrder: widget.sortBy.sortOrder.queryParam,
        filters: widget.filters);
    final series = res.result;
    final paging = res.paging!;
    setState(() {
      _series ??= [];
      _series!.addAll(series);
      _paging = paging;
    });
    _isLoading = false;
  }
}

class SeriesView extends StatefulWidget {
  final List<FFSeries> series;
  final List<UserCollection> userCollections;
  final AlumniAccount? artist;
  final ScrollController? scrollController;
  final bool isScrollable;
  final EdgeInsets padding;

  const SeriesView({
    required this.series,
    required this.userCollections,
    this.scrollController,
    this.artist,
    super.key,
    this.isScrollable = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<SeriesView> createState() => _SeriesViewState();
}

class _SeriesViewState extends State<SeriesView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller: _scrollController,
        shrinkWrap: true,
        physics: widget.isScrollable
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        slivers: [
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 188 / 307,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final series = widget.series[index];
                final border = Border(
                  top: const BorderSide(
                    color: AppColor.auGreyBackground,
                  ),
                  right: BorderSide(
                    color:
                        // if index is even, show border on the right
                        index.isEven
                            ? AppColor.auGreyBackground
                            : Colors.transparent,
                  ),
                  // if last row, add border on the bottom
                  bottom: index >= widget.series.length - 2
                      ? const BorderSide(
                          color: AppColor.auGreyBackground,
                        )
                      : BorderSide.none,
                );
                return _seriesItem(context, series, border);
              },
              childCount: widget.series.length,
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 188 / 307,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final collection = widget.userCollections[index];
                final border = Border(
                  top: const BorderSide(
                    color: AppColor.auGreyBackground,
                  ),
                  right: BorderSide(
                    color:
                        // if index is even, show border on the right
                        index.isEven
                            ? AppColor.auGreyBackground
                            : Colors.transparent,
                  ),
                  // if last row, add border on the bottom
                  bottom: index >= widget.series.length - 2
                      ? const BorderSide(
                          color: AppColor.auGreyBackground,
                        )
                      : BorderSide.none,
                );
                return _userCollectionItem(context, collection, border);
              },
              childCount: widget.userCollections.length,
            ),
          ),
          SliverPadding(
            padding: widget.padding,
            sliver: const SliverToBoxAdapter(),
          ),
        ],
      );

  Widget _seriesItem(BuildContext context, FFSeries series, Border border) =>
      Container(
        decoration: BoxDecoration(
          // border on the top and right
          border: border,
          color: Colors.transparent,
        ),
        padding: const EdgeInsets.all(8),
        child: FfSeriesInfoThumbnail(series: series),
      );

  Widget _userCollectionItem(
      BuildContext context, UserCollection collection, Border border) {
    return Container(
      decoration: BoxDecoration(
        // border on the top and right
        border: border,
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(8),
      child: UserCollectionThumnbail(
          collection: collection, artist: widget.artist),
    );
  }
}
