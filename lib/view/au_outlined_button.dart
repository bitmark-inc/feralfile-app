import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class AuOutlinedButton extends StatelessWidget {
  final String text;
  final Function() onPress;

  const AuOutlinedButton({Key? key, required this.text, required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: AutonomyOutlineButtonClipper(),
          child: Container(
              width: double.infinity, height: 30, color: Colors.black),
        ),
        Container(
          width: double.infinity,
          child: ClipPath(
              clipper: AutonomyButtonClipper(),
              child: TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                  text.toUpperCase(),
                  style: appTextTheme.caption,
                ),
                onPressed: onPress,
              )),
        ),
      ],
    );
  }
}
