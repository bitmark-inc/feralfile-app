import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CastButton extends StatelessWidget {
  final VoidCallback? onCastTap;
  final bool isCasting;

  const CastButton({super.key, this.onCastTap, this.isCasting = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onCastTap,
      child: Semantics(
        label: 'cast_icon',
        child: SvgPicture.asset(
          'assets/images/cast_icon.svg',
          colorFilter: ColorFilter.mode(
              isCasting ? theme.auSuperTeal : theme.colorScheme.secondary,
              BlendMode.srcIn),
        ),
      ),
    );
  }
}
