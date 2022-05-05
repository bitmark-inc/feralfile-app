import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class AuFilledButton extends StatelessWidget {
  final String text;
  final Function()? onPress;
  final Color color;
  final TextStyle? textStyle;
  final bool isProcessing;

  const AuFilledButton(
      {Key? key,
      required this.text,
      required this.onPress,
      this.color = Colors.black,
      this.isProcessing = false,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isProcessing
                ? Container(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      backgroundColor: Colors.grey,
                      strokeWidth: 2.0,
                    ),
                    height: 14.0,
                    width: 14.0,
                    margin: EdgeInsets.only(right: 8.0),
                  )
                : SizedBox(),
            Text(
              text.toUpperCase(),
              style: textStyle ?? appTextTheme.button,
            ),
          ],
        ),
        onPressed: onPress,
      ),
    );
  }
}
