import 'package:flutter/material.dart';

class FilledButton extends StatelessWidget {

  final String text;
  final Function() onPress;

  const FilledButton({Key? key, required this.text, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: Theme.of(context).buttonColor,
                // shape: RoundedRectangleBorder(
                //   borderRadius: BorderRadius.circular(30.0),
                // ),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(
              text,
              style: Theme.of(context).textTheme.button,
            ),
            onPressed: onPress,
          ),
        ),
      ],
    );
  }
}