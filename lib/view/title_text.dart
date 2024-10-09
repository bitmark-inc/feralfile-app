import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class TitleText extends StatelessWidget {
  const TitleText({required this.title, super.key, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: style ?? Theme.of(context).textTheme.ppMori700White24);
}
