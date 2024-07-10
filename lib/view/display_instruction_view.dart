import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DisplayInstructionView extends StatelessWidget {
  final Function? onScanQRTap;

  const DisplayInstructionView({super.key, this.onScanQRTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final st = theme.textTheme.ppMori400White14;
    final indexes = [0, 1, 2, 3, 4];
    return Column(
      children: [
        Text(
          'available_on_tv'.tr(),
          style: theme.textTheme.ppMori400Grey14,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: indexes.map((index) {
              final instruction = 'display_instruction_${index + 1}'.tr();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: st,
                    ),
                    Expanded(
                      flex: index == 2 ? 0 : 1,
                      child: index != 3 || onScanQRTap == null
                          ? Text(
                              instruction,
                              style: st,
                            )
                          : RichText(
                              text: TextSpan(
                                style: st,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'scan_the_qrcode'.tr(),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        onScanQRTap?.call();
                                      },
                                    style: st.copyWith(
                                        decoration: TextDecoration.underline),
                                  ),
                                  TextSpan(
                                    text: 'display_instruction_4_2'.tr(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 5),
                    if (index == 2)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: AppColor.feralFileLightBlue,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          child: SvgPicture.asset(
                            'assets/images/cast_icon.svg',
                            height: 12,
                            width: 12,
                            colorFilter: const ColorFilter.mode(
                              AppColor.primaryBlack,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
