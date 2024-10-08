import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bring_art_into'.tr(),
          style: theme.textTheme.ppMori400Grey14,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'display_on_tv'.tr(),
          color: AppColor.feralFileLightBlue,
          onTap: () {
            injector<NavigationService>().hideInfoDialog();
            unawaited(_showHowToDisplay(
              context,
              HowToDisplayOnTV(
                onScanQRTap: onScanQRTap,
              ),
            ));
          },
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'display_on_browser'.tr(),
          color: AppColor.feralFileLightBlue,
          onTap: () {
            injector<NavigationService>().hideInfoDialog();
            unawaited(_showHowToDisplay(
              context,
              HowToDisplayOnBrowser(
                onScanQRTap: onScanQRTap,
              ),
            ));
          },
        ),
      ],
    );
  }

  Future<void> _showHowToDisplay(BuildContext context, Widget child) async {
    await UIHelper.showFlexibleDialog(
      context,
      child,
      isDismissible: true,
    );
  }
}

class HowToDisplayOnTV extends StatelessWidget {
  final Function? onScanQRTap;

  const HowToDisplayOnTV({super.key, this.onScanQRTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori700White24,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'how_to_display'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Padding(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.asset(
                    'assets/images/circle_close.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori400Black14,
                    children: [
                      TextSpan(
                        text: "${'step'.tr()} 1: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "${'search_by_'.tr()} ",
                      ),
                      WidgetSpan(
                        baseline: TextBaseline.alphabetic,
                        alignment: PlaceholderAlignment.baseline,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            textScaler: const TextScaler.linear(1),
                            'feral_file'.tr(),
                            style: theme.textTheme.ppMori700Black14,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: " ${'in_google_play_store'.tr()}.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori400Black14,
                    children: [
                      TextSpan(
                        text: "${'step'.tr()} 2: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            onScanQRTap?.call();
                          },
                        text: 'scan_the_qr_code'.tr(),
                        style: onScanQRTap != null
                            ? const TextStyle(
                                decoration: TextDecoration.underline,
                              )
                            : null,
                      ),
                      TextSpan(
                        text: " ${'on_your_TV'.tr()}.",
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class HowToDisplayOnBrowser extends StatelessWidget {
  final Function? onScanQRTap;

  const HowToDisplayOnBrowser({super.key, this.onScanQRTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori700White24,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'how_to_display'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Padding(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.asset(
                    'assets/images/circle_close.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori400Black14,
                    children: [
                      TextSpan(
                        text: "${'step'.tr()} 1: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "${'open'.tr()} ",
                      ),
                      WidgetSpan(
                        baseline: TextBaseline.alphabetic,
                        alignment: PlaceholderAlignment.baseline,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            'https://display.feralfile.com',
                            textScaler: const TextScaler.linear(1),
                            style: theme.textTheme.ppMori700Black14,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: " ${'on_your_TV_web_browser'.tr()}.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori400Black14,
                    children: [
                      TextSpan(
                        text: "${'step'.tr()} 2: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            onScanQRTap?.call();
                          },
                        text: 'scan_the_qr_code'.tr(),
                        style: onScanQRTap != null
                            ? const TextStyle(
                                decoration: TextDecoration.underline,
                              )
                            : null,
                      ),
                      TextSpan(
                        text: " ${'on_your_TV'.tr()}.",
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
