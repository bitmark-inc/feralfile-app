import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color color;

  const SkeletonContainer({
    this.width = double.infinity,
    this.height = double.infinity,
    this.color = AppColor.auLightGrey,
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      builder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
