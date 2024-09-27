import 'dart:async';

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
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
    final supportedDisplayBranches = _getSupportedDisplayBranches();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Text(
            'bring_art_into'.tr(),
            style: theme.textTheme.ppMori400Grey14,
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          itemBuilder: (context, index) {
            final item = supportedDisplayBranches[index];
            return Column(
              children: [
                _item(context, title: item.title, onTap: item.onTap),
                addOnlyDivider(color: AppColor.primaryBlack),
              ],
            );
          },
          itemCount: supportedDisplayBranches.length,
          shrinkWrap: true,
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

  List<DisplayItem> _getSupportedDisplayBranches() => [
        DisplayItem(
          branch: SupportedDisplayBranch.samsung,
          onTap: (BuildContext context) {
            final theme = Theme.of(context);
            final numberFormater = NumberFormat('00');
            final child = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Art on',
                              style: theme.textTheme.ppMori700White24,
                            ),
                            SupportedDisplayBranch.samsung.logo,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset('assets/images/left-arrow.svg',
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(
                              AppColor.white,
                              BlendMode.srcIn,
                            )),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SupportedDisplayBranch.samsung.demoPicture,
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            numberFormater.format(1),
                            style: theme.textTheme.ppMori400White14,
                          ),
                          const SizedBox(width: 20),
                          RichText(
                            textScaler: MediaQuery.textScalerOf(context),
                            text: TextSpan(
                              style: theme.textTheme.ppMori400White14,
                              children: [
                                TextSpan(
                                  text: "${'install'.tr()} ",
                                ),
                                WidgetSpan(
                                  baseline: TextBaseline.alphabetic,
                                  alignment: PlaceholderAlignment.baseline,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: AppColor.white),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Text(
                                      textScaler: const TextScaler.linear(1),
                                      'feral_file'.tr(),
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: " ${'in_google_play_store'.tr()}.",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            numberFormater.format(2),
                            style: theme.textTheme.ppMori400White14,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              'launch_the_feralfile_app_on_display'.tr(),
                              style: theme.textTheme.ppMori400White14,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            numberFormater.format(3),
                            style: theme.textTheme.ppMori400White14,
                          ),
                          const SizedBox(width: 20),
                          RichText(
                            textScaler: MediaQuery.textScalerOf(context),
                            text: TextSpan(
                              style: theme.textTheme.ppMori400White14,
                              children: [
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
                      )
                    ],
                  )
                ],
              ),
            );
            _showHowToDisplay(context, child);
          },
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.lg,
          onTap: (BuildContext context) {},
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.chromecast,
          onTap: (BuildContext context) {},
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.sony,
          onTap: (BuildContext context) {},
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.Hisense,
          onTap: (BuildContext context) {},
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.TCL,
          onTap: (BuildContext context) {},
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.other,
          onTap: (BuildContext context) {},
        ),
      ];

  Widget _item(BuildContext context,
      {required String title, required Function(BuildContext context)? onTap}) {
    final theme = Theme.of(context);
    return Container(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets
          .copyWith(top: 24, bottom: 24),
      child: GestureDetector(
        onTap: () {
          onTap?.call(context);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.ppMori400White14,
              ),
            ),
            const SizedBox(width: 16),
            SvgPicture.asset(
              'assets/images/iconForward.svg',
              colorFilter: const ColorFilter.mode(
                AppColor.white,
                BlendMode.srcIn,
              ),
            )
          ],
        ),
      ),
    );
  }
}

enum SupportedDisplayBranch {
  samsung,
  lg,
  chromecast,
  sony,
  Hisense,
  TCL,
  other;

  String get title {
    switch (this) {
      case SupportedDisplayBranch.samsung:
        return 'samsung'.tr();
      case SupportedDisplayBranch.lg:
        return 'lg'.tr();
      case SupportedDisplayBranch.chromecast:
        return 'chromecast'.tr();
      case SupportedDisplayBranch.sony:
        return 'sony'.tr();
      case SupportedDisplayBranch.Hisense:
        return 'hisense'.tr();
      case SupportedDisplayBranch.TCL:
        return 'tcl'.tr();
      case SupportedDisplayBranch.other:
        return 'other'.tr();
    }
  }

  Widget get logo => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.amber,
        ),
      );

  Widget get demoPicture {
    return Container(
      height: 300,
      width: 300,
      color: Colors.amber,
    );
  }
}

class DisplayItem {
  final SupportedDisplayBranch branch;
  final Function(BuildContext context)? onTap;

  DisplayItem({required this.branch, required this.onTap});

  Widget get logo => branch.logo;

  String get title => branch.title;
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
