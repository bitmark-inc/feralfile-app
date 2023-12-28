import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CastButton extends StatelessWidget {
  final VoidCallback? onCastTap;
  final bool isCasting;
  final String? text;

  const CastButton(
      {super.key, this.onCastTap, this.isCasting = false, this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 10, top: 10),
      child: GestureDetector(
        onTap: onCastTap,
        child: Semantics(
          label: 'cast_icon',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColor.feralFileLightBlue,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (text != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        text!,
                        style: theme.textTheme.ppMori400Black14.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  SvgPicture.asset(
                    'assets/images/cast_icon.svg',
                    colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
