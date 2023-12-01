import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddButton extends StatelessWidget {
  final Function() onTap;
  final double size;

  const AddButton({required this.onTap, super.key, this.size = 22});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        'assets/images/add_icon.svg',
        width: size,
        height: size,
      ));
}

class RemoveButton extends StatelessWidget {
  final Function() onTap;
  final double size;
  final Color? color;

  const RemoveButton(
      {required this.onTap, super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        'assets/images/remove_icon.svg',
        width: size,
        height: size,
        colorFilter:
            color == null ? null : ui.ColorFilter.mode(color!, BlendMode.srcIn),
      ));
}
