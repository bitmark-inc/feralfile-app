import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class TitleText extends StatelessWidget {
  const TitleText(
      {required this.title,
      super.key,
      this.ellipsis = true,
      this.isCentered = false,
      this.fontSize = 24});

  final String title;
  final bool isCentered;
  final bool ellipsis;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.ppMori700White24.copyWith(
              fontSize: fontSize,
            ),
        maxLines: ellipsis ? null : 2,
        overflow: ellipsis ? TextOverflow.ellipsis : null,
        textAlign: isCentered ? TextAlign.center : null,
      );
}
