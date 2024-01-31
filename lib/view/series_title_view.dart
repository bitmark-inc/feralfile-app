import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class SeriesTitleView extends StatelessWidget {
  const SeriesTitleView(
      {required this.series, super.key, this.crossAxisAlignment, this.artist});

  final FFSeries series;
  final FFArtist? artist;
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        Text(
          artist?.alias ?? '',
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 3),
        Text(
          series.title,
          style: theme.textTheme.ppMori700White14.copyWith(
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
