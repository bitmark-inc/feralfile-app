import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FFCastButton extends StatelessWidget {
  final VoidCallback? onCastTap;
  final bool isCasting;
  final String? text;

  const FFCastButton(
      {super.key, this.onCastTap, this.isCasting = false, this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onCastTap,
      child: Semantics(
        label: 'cast_icon',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColor.feralFileLightBlue,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                  height: 20,
                  colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CastButton extends StatelessWidget {
  final VoidCallback? onCastTap;
  final bool isCasting;

  const CastButton({super.key, this.onCastTap, this.isCasting = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onCastTap,
        child: Semantics(
          label: 'cast_icon',
          child: SvgPicture.asset(
            'assets/images/cast_icon.svg',
            colorFilter: ColorFilter.mode(
                isCasting ? AppColor.feralFileHighlight : AppColor.white,
                BlendMode.srcIn),
          ),
        ),
      );
}
