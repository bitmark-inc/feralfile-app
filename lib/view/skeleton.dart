import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color color;
  final Color highlightColor;

  const SkeletonContainer({
    this.width = double.infinity,
    this.height = double.infinity,
    this.color = AppColor.auLightGrey,
    this.highlightColor = const Color(0xFFF5F5F5),
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    super.key,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: color,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
        ),
      );
}
