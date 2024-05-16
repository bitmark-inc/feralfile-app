import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ImageBackground extends StatelessWidget {
  final Widget child;
  final Color color;

  const ImageBackground(
      {required this.child, this.color = AppColor.auLightGrey, super.key});

  @override
  Widget build(BuildContext context) =>
      DecoratedBox(decoration: BoxDecoration(color: color), child: child);
}
