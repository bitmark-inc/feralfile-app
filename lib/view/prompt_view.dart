import 'package:autonomy_flutter/model/prompt.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PromptView extends StatelessWidget {
  final Prompt prompt;
  final Function? onTap;
  final bool expandable;

  const PromptView(
      {required this.prompt, super.key, this.onTap, this.expandable = false});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!expandable && prompt.colorAsColor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: prompt.colorAsColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  Text(
                    prompt.title ?? 'prompt'.tr(),
                    style: theme.textTheme.moMASans400Grey12,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (expandable && prompt.colorAsColor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: prompt.colorAsColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      prompt.description,
                      style: theme.textTheme.moMASans700Black18,
                      maxLines: expandable ? null : 2,
                      overflow: expandable ? null : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
