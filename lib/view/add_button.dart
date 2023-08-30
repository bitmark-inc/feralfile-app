import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

class AddButton extends StatelessWidget {
  final Function() onTap;
  final double size;

  const AddButton({Key? key, required this.onTap, this.size = 22})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(
          "assets/images/add_icon.svg",
          width: size,
          height: size,
        ));
  }
}

class RemoveButton extends StatelessWidget {
  final Function() onTap;
  final double size;
  final Color? color;

  const RemoveButton(
      {Key? key, required this.onTap, this.size = 22, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(
          "assets/images/remove_icon.svg",
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ui.ColorFilter.mode(color!, BlendMode.srcIn),
        ));
  }
}
