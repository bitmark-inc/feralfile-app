import 'package:flutter/material.dart';

class GestureConstrainWidget extends StatelessWidget {
  const GestureConstrainWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48,
        minWidth: 48,
      ),
      child: child,
    );
  }
}
