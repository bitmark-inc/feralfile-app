import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

enum ButtonState {
  primary,
  secondary,
  disabled,
}

class Button extends StatelessWidget {
  final String text;
  final ButtonState state;

  const Button({
    super.key,
    required this.text,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: state == ButtonState.disabled ? null : () {},
      child: Text(text, style: TextStyle(
        color: state == ButtonState.disabled ? Colors.grey : Colors.white,
      )),
    );
  }
}

@UseCase(name: 'Primary', type: Button)
Widget primaryButton(BuildContext context) {
  return Button(
    text: 'Primary',
    state: ButtonState.primary,
  );
}

@UseCase(name: 'Secondary', type: Button)
Widget secondaryButton(BuildContext context) {
  return Button(
    text: 'Secondary',
    state: ButtonState.secondary,
  );
}

@UseCase(name: 'Disabled', type: Button)
Widget disabledButton(BuildContext context) {
  return Button(
    text: 'Disabled',
    state: ButtonState.disabled,
  );
}