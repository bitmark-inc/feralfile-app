import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TappableForwardRow extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? rightWidget;
  final Function() onTap;

  const TappableForwardRow(
      {Key? key, this.leftWidget, this.rightWidget, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leftWidget ?? SizedBox(),
          Row(
            children: [
              rightWidget ?? SizedBox(),
              SizedBox(width: 8.0),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          )
        ],
      ),
      onTap: () {
        onTap();
      },
      // onTap: onTap,
    );
  }
}
