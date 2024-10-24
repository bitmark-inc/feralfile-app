import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ArtworkTitleView extends StatelessWidget {
  const ArtworkTitleView({
    required this.artwork,
    super.key,
    this.crossAxisAlignment,
  });

  final Artwork artwork;
  final CrossAxisAlignment? crossAxisAlignment;
  final showArtworkName = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSingle = artwork.series?.isSingle ?? false;
    final title =
        '${artwork.series!.displayTitle} '
        '${isSingle ? '' : '(${artwork.name})'}';
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: Text(
            artwork.series!.artist?.displayAlias ?? '',
            style: theme.textTheme.ppMori400White14,
          ),
          onTap: () async => {
            if (artwork.series?.artist?.alumniAccount?.slug != null)
              {
                injector<NavigationService>().openFeralFileArtistPage(
                    artwork.series!.artist!.alumniAccount!.slug!)
              }
          },
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: theme.textTheme.ppMori700White14.copyWith(
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
