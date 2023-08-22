import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
