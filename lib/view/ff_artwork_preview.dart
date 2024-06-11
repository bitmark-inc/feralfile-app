import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/view/feralfile_artwork_preview_widget.dart';
import 'package:autonomy_flutter/view/series_title_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FeralFileArtworkPreview extends StatelessWidget {
  const FeralFileArtworkPreview({required this.payload, super.key});

  final FeralFileArtworkPreviewPayload payload;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: FeralfileArtworkPreviewWidget(
              payload: FeralFileArtworkPreviewWidgetPayload(
                artwork: payload.artwork,
                isMute: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
            child: GestureDetector(
              onTap: () async => Navigator.of(context).pushNamed(
                AppRouter.feralFileSeriesPage,
                arguments: FeralFileSeriesPagePayload(
                  seriesId: payload.artwork.series!.id,
                  exhibitionId: payload.artwork.series!.exhibitionID,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 5,
                    child: SeriesTitleView(
                        series: payload.artwork.series!,
                        artist: payload.artwork.series!.artist),
                  ),
                  SvgPicture.asset(
                    'assets/images/icon_series.svg',
                    width: 22,
                    height: 22,
                  )
                ],
              ),
            ),
          ),
        ],
      );
}

class FeralFileArtworkPreviewPayload {
  final Artwork artwork;

  const FeralFileArtworkPreviewPayload({
    required this.artwork,
  });
}
