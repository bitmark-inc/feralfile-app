import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/view/series_title_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class FeralFileArtworkPreview extends StatelessWidget {
  const FeralFileArtworkPreview({required this.payload, super.key});

  final FeralFileArtworkPreviewPayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ArtworkPreviewWidget(
            identity: ArtworkIdentity(payload.tokenId, ''),
            useIndexer: true,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
          child: GestureDetector(
            onTap: () async => Navigator.of(context).pushNamed(
              AppRouter.feralFileSeriesPage,
              arguments: FeralFileSeriesPagePayload(
                seriesId: payload.series.id,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 5,
                  child: SeriesTitleView(
                      series: payload.series, artist: payload.series.artist),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${payload.artwork.index + 1}/${payload.series.settings?.maxArtwork ?? '--'}',
                    style:
                        theme.textTheme.ppMori400White12.copyWith(fontSize: 10),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FeralFileArtworkPreviewPayload {
  final String tokenId;
  final FFSeries series;
  final Artwork artwork;

  const FeralFileArtworkPreviewPayload({
    required this.tokenId,
    required this.series,
    required this.artwork,
  });
}
