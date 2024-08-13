import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SeriesView extends StatefulWidget {
  final List<FFSeries> series;

  const SeriesView({required this.series, super.key});

  @override
  State<SeriesView> createState() => _SeriesViewState();
}

class _SeriesViewState extends State<SeriesView> {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
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
        ));
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
                series.title ?? '',
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
