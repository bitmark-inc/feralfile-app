import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class AuFilledButton extends StatelessWidget {
  final String text;
  final Function()? onPress;

  const AuFilledButton({Key? key, required this.text, required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.button,
        ),
        onPressed: onPress,
      ),
    );
  }
}
