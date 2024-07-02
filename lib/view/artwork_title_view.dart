import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
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
    final title = artwork.series!.displayTitle +
        (artwork.isYokoOnoPublicVersion ? '' : ' ${artwork.name}');
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        Text(
          artwork.series!.artist?.alias ?? '',
          style: theme.textTheme.ppMori400White14,
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
