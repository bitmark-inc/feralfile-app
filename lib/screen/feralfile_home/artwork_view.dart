import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
  State<ExploreSeriesView> createState() => _ExploreSeriesViewState();

  bool isEqual(Object other) {
    return other is ExploreSeriesView &&
        other.searchText == searchText &&
        other.filters == filters &&
        other.sortBy == sortBy &&
        other.pageSize == pageSize;
  }
}

class _ExploreSeriesViewState extends State<ExploreSeriesView> {
  List<FFSeries>? _series;
  late Paging _paging;
  late ScrollController _scrollController;
  bool _isLoading = false;

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
    if (!oldWidget.isEqual(widget) || true) {
      unawaited(_fetchSeries(context));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _loadingView(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('No series found', style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _seriesView(BuildContext context, List<FFSeries> series) {
    return SeriesView(
      series: series,
      scrollController: _scrollController,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_series == null) {
      return _loadingView(context);
    } else if (_series!.isEmpty) {
      return _emptyView(context);
    } else {
      return Expanded(child: _seriesView(context, _series!));
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
    final paging = res.paging;
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
    final paging = res.paging;
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
  final ScrollController? scrollController;

  const SeriesView({required this.series, this.scrollController, super.key});

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
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      shrinkWrap: true,
      slivers: [
        SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 188 / 307,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final series = widget.series[index];
                return _seriesItem(context, series);
              },
              childCount: widget.series.length,
            ))
      ],
    );
  }

  Widget _seriesInfo(BuildContext context, FFSeries series) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.ppMori400White12;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                series.artist?.alias ?? '',
                style: defaultStyle,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                series.title,
                style: defaultStyle,
                overflow: TextOverflow.ellipsis,
              ),
              if (series.exhibition != null)
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: defaultStyle.copyWith(color: AppColor.auQuickSilver),
                    children: [
                      const TextSpan(
                        text: 'Exhibited in: ',
                      ),
                      TextSpan(
                        text: series.exhibition!.title,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _gotoExhibitionDetails(context, series.exhibition!);
                          },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _seriesItem(BuildContext context, FFSeries series) {
    return GestureDetector(
      onTap: () {
        _gotoSeriesDetails(context, series);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.network(
                      series.thumbnailUrl ?? '',
                      fit: BoxFit.fitWidth,
                    ),
                    // Image.network(
                    //   series.thumbnailUrl ?? '',
                    //   fit: BoxFit.fitWidth,
                    // ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _seriesInfo(context, series),
          ],
        ),
      ),
    );
  }

  void _gotoSeriesDetails(BuildContext context, FFSeries series) {
    if (series.isSingle) {
      final artwork = series.artwork!;
      Navigator.of(context).pushNamed(
        AppRouter.ffArtworkPreviewPage,
        arguments: FeralFileArtworkPreviewPagePayload(
          artwork: artwork,
        ),
      );
    } else {
      Navigator.of(context).pushNamed(
        AppRouter.feralFileSeriesPage,
        arguments: FeralFileSeriesPagePayload(
          seriesId: series.id,
          exhibitionId: series.exhibitionID,
        ),
      );
    }
  }

  void _gotoExhibitionDetails(BuildContext context, Exhibition exhibition) {
    Navigator.of(context).pushNamed(AppRouter.exhibitionDetailPage,
        arguments: ExhibitionDetailPayload(
          exhibitions: [exhibition],
          index: 0,
        ));
  }
}
