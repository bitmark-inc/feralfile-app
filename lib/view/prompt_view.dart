import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PromptView extends StatelessWidget {
  final String text;
  final Function? onTap;
  final bool expandable;

  const PromptView(
      {required this.text, super.key, this.onTap, this.expandable = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColor.white,
      ),
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!();
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'prompt'.tr(),
                      style: theme.textTheme.moMASans400Grey12,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      style: theme.textTheme.moMASans700Black18,
                      maxLines: expandable ? null : 2,
                      overflow: expandable ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
