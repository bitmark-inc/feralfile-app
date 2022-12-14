import 'package:flutter/material.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class PrimaryButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  const PrimaryButton({Key? key, this.onTap, this.color, this.text, this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(73),
          color: color ?? theme.auSuperTeal,
        ),
        child: Center(
          child: Text(
            text ?? '',
            style: theme.textTheme.ppMori400Black12,
          ),
        ),
      ),
    );
  }
}
