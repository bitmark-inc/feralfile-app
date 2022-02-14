import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class AuFilledButton extends StatelessWidget {
  final String text;
  final Function()? onPress;
  final Color color;
  final TextStyle? textStyle;

  const AuFilledButton(
      {Key? key,
      required this.text,
      required this.onPress,
      this.color = Colors.black,
      this.textStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(
          text.toUpperCase(),
          style: textStyle ?? appTextTheme.button,
        ),
        onPressed: onPress,
      ),
    );
  }
}
