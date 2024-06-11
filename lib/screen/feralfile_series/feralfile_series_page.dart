import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/ff_artwork_thumbnail_view.dart';
import 'package:autonomy_flutter/view/series_title_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class FeralFileSeriesPage extends StatefulWidget {
  const FeralFileSeriesPage({required this.payload, super.key});

  final FeralFileSeriesPagePayload payload;

  @override
  State<FeralFileSeriesPage> createState() => _FeralFileSeriesPageState();
}

class _FeralFileSeriesPageState extends State<FeralFileSeriesPage> {
  late final FeralFileSeriesBloc _feralFileSeriesBloc;
  final _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
  static const _padding = 14.0;
  static const _axisSpacing = 10.0;
  final PagingController<int, Artwork> _pagingController =
      PagingController(firstPageKey: 0);
  static const _pageSize = 300;

  @override
  void initState() {
    super.initState();
    _feralFileSeriesBloc = context.read<FeralFileSeriesBloc>();
    _feralFileSeriesBloc.add(FeralFileSeriesGetSeriesEvent(
        widget.payload.seriesId, widget.payload.exhibitionId));
    _pagingController.addPageRequestListener((pageKey) async {
      await _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await injector<FeralFileService>().getSeriesArtworks(
          widget.payload.seriesId, widget.payload.exhibitionId,
          offset: pageKey,
          // ignore: avoid_redundant_argument_values
          limit: _pageSize);
      final isLastPage = !newItems.paging.shouldLoadMore;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems.result);
      } else {
        final nextPageKey = pageKey + _pageSize;
        _pagingController.appendPage(newItems.result, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<FeralFileSeriesBloc, FeralFileSeriesState>(
        builder: (context, state) => Scaffold(
            appBar: _getAppBar(context, state.series),
            backgroundColor: AppColor.primaryBlack,
            body: _body(context, state.series)),
        listener: (context, state) {},
      );

  AppBar _getAppBar(BuildContext buildContext, FFSeries? series) => getFFAppBar(
        buildContext,
        onBack: () => Navigator.pop(buildContext),
        title: series == null
            ? const SizedBox()
            : SeriesTitleView(
                series: series,
                artist: series.artist,
                crossAxisAlignment: CrossAxisAlignment.center),
      );

  Widget _body(BuildContext context, FFSeries? series) {
    if (series == null) {
      return _loadingIndicator();
    }
    return _artworkSliverGrid(context, series);
  }

  Widget _loadingIndicator() => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: loadingIndicator(valueColor: AppColor.auGrey),
        ),
      );

  Widget _artworkSliverGrid(BuildContext context, FFSeries series) => Padding(
        padding:
            const EdgeInsets.only(left: _padding, right: _padding, bottom: 20),
        child: CustomScrollView(
          slivers: [
            PagedSliverGrid<int, Artwork>(
              pagingController: _pagingController,
              showNewPageErrorIndicatorAsGridChild: false,
              showNewPageProgressIndicatorAsGridChild: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: _axisSpacing,
                mainAxisSpacing: _axisSpacing,
                crossAxisCount: 3,
              ),
              builderDelegate: PagedChildBuilderDelegate<Artwork>(
                itemBuilder: (context, artwork, index) =>
                    FFArtworkThumbnailView(
                  artwork: artwork,
                  cacheSize: (MediaQuery.sizeOf(context).width -
                          _padding * 2 -
                          _axisSpacing * 2) ~/
                      3,
                  onTap: () async {
                    final controllingDevice =
                        _canvasDeviceBloc.state.controllingDevice;
                    if (controllingDevice != null) {
                      final castRequest = CastExhibitionRequest(
                          exhibitionId: series.exhibitionID,
                          katalog: ExhibitionKatalog.ARTWORK,
                          katalogId: artwork.id);
                      _canvasDeviceBloc.add(
                        CanvasDeviceCastExhibitionEvent(
                          controllingDevice,
                          castRequest,
                        ),
                      );
                    }
                    await Navigator.of(context).pushNamed(
                      AppRouter.ffArtworkPreviewPage,
                      arguments: FeralFileArtworkPreviewPagePayload(
                        artwork: artwork.copyWith(series: series),
                      ),
                    );
                  },
                ),
                newPageProgressIndicatorBuilder: (context) =>
                    _loadingIndicator(),
                firstPageErrorIndicatorBuilder: (context) => const SizedBox(),
                newPageErrorIndicatorBuilder: (context) => const SizedBox(),
              ),
            )
          ],
        ),
      );
}

class FeralFileSeriesPagePayload {
  final String seriesId;
  final String exhibitionId;

  const FeralFileSeriesPagePayload({
    required this.seriesId,
    required this.exhibitionId,
  });
}
