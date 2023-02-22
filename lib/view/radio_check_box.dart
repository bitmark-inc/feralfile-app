import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class RadioCheckBox extends StatelessWidget {
  final bool? isChecked;
  final Function(bool?)? onTap;
  const RadioCheckBox({Key? key, this.isChecked, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RoundCheckBox(
      border: Border.all(
        color: theme.colorScheme.secondary,
        width: 1.5,
      ),
      uncheckedColor: theme.colorScheme.primary,
      uncheckedWidget: Container(
        padding: const EdgeInsets.all(4),
      ),
      checkedColor: theme.colorScheme.primary,
      checkedWidget: Container(
        padding: const EdgeInsets.all(4),
        child: SvgPicture.asset(
          'assets/images/check-icon.svg',
          color: theme.colorScheme.secondary,
        ),
      ),
      animationDuration: const Duration(milliseconds: 100),
      isChecked: isChecked,
      size: 24,
      onTap: onTap,
    );
  }
}
