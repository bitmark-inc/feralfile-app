import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TappableForwardRow extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? rightWidget;
  final Widget? bottomWidget;
  final Function()? onTap;
  const TappableForwardRow(
      {Key? key,
      this.leftWidget,
      this.rightWidget,
      this.bottomWidget,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: _content(),
      onTap: onTap,
      // onTap: onTap,
    );
  }

  Widget _content() {
    if (bottomWidget == null) return _contentRow();
    return Column(
      children: [
        _contentRow(),
        SizedBox(height: 16),
        Row(children: [Expanded(child: bottomWidget!)]),
      ],
    );
  }

  Widget _contentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: leftWidget ?? SizedBox()),
        Row(
          children: [
            rightWidget ?? SizedBox(),
            if (onTap != null) ...[
              SizedBox(width: 8.0),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ],
        )
      ],
    );
  }
}
