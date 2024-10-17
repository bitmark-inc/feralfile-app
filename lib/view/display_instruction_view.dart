import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
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
            'what_kinds_of_tv'.tr(),
            style: theme.textTheme.ppMori400Grey14,
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          itemBuilder: (context, index) {
            final item = supportedDisplayBranches[index];
            return Column(
              children: [
                _item(context, item: item),
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

  void _onDisplayTap(
      BuildContext context, SupportedDisplayBranch displayBranch) {
    injector<NavigationService>().showHowToDisplay(displayBranch, onScanQRTap);
  }

  List<DisplayItem> _getSupportedDisplayBranches() => [
        DisplayItem(
          branch: SupportedDisplayBranch.samsung,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.lg,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.chromecast,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.sony,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.Hisense,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.TCL,
          onTap: _onDisplayTap,
        ),
        DisplayItem(
          branch: SupportedDisplayBranch.other,
          onTap: _onDisplayTap,
        ),
      ];

  Widget _commingSoonLabel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColor.auQuickSilver),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text('coming_soon'.tr(),
          style: theme.textTheme.ppMori400Grey14.copyWith(
            color: AppColor.auQuickSilver,
          )),
    );
  }

  Widget _item(BuildContext context, {required DisplayItem item}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        item.onTap?.call(context, item.branch);
      },
      child: Container(
        padding: ResponsiveLayout.pageHorizontalEdgeInsets
            .copyWith(top: 24, bottom: 24),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.ppMori400White14,
              ),
            ),
            const SizedBox(width: 16),
            if (item.branch.isComingSoon)
              _commingSoonLabel(context)
            else
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
        return 'Samsung';
      case SupportedDisplayBranch.lg:
        return 'LG'.tr();
      case SupportedDisplayBranch.chromecast:
        return 'Chromecast'.tr();
      case SupportedDisplayBranch.sony:
        return 'Sony'.tr();
      case SupportedDisplayBranch.Hisense:
        return 'Hisense'.tr();
      case SupportedDisplayBranch.TCL:
        return 'TCL'.tr();
      case SupportedDisplayBranch.other:
        return 'Other'.tr();
    }
  }

  bool get isComingSoon => this == SupportedDisplayBranch.lg;

  Widget get logo {
    const color = AppColor.white;
    const colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    const height = 18.0;
    switch (this) {
      case SupportedDisplayBranch.samsung:
        return SvgPicture.asset(
          'assets/images/samsung_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.lg:
        return SvgPicture.asset(
          'assets/images/lg_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.chromecast:
        return SvgPicture.asset(
          'assets/images/chromecast_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.sony:
        return SvgPicture.asset(
          'assets/images/sony_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.Hisense:
        return SvgPicture.asset(
          'assets/images/hisense_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.TCL:
        return SvgPicture.asset(
          'assets/images/tcl_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
      case SupportedDisplayBranch.other:
        return SvgPicture.asset(
          'assets/images/other_branch_logo.svg',
          colorFilter: colorFilter,
          height: height,
        );
    }
  }

  Widget demoPicture(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case SupportedDisplayBranch.samsung:
        return Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              'assets/images/Samsung_TV_living_room.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColor.primaryBlack,
                    AppColor.primaryBlack.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 6, left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently supporting 2023 onward models',
                      style: theme.textTheme.ppMori700White12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case SupportedDisplayBranch.lg:
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Image.asset(
              'assets/images/Android_TV_living_room.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
            Positioned.fill(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.primaryBlack.withOpacity(0.5),
                ),
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColor.primaryBlack,
                        AppColor.primaryBlack.withOpacity(0),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 6, left: 10),
                    child: Text(
                      'Support for LG TVs is coming soon. ',
                      style: theme.textTheme.ppMori700White12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case SupportedDisplayBranch.chromecast:
      case SupportedDisplayBranch.sony:
      case SupportedDisplayBranch.Hisense:
      case SupportedDisplayBranch.TCL:
        return Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              'assets/images/Android_TV_living_room.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColor.primaryBlack,
                    AppColor.primaryBlack.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 6, left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently supporting 2021 onward models',
                      style: theme.textTheme.ppMori700White12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case SupportedDisplayBranch.other:
        return Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              'assets/images/Web_display_TV_living_room.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColor.primaryBlack,
                    AppColor.primaryBlack.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 6, left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use the TV web browser, or any web browser.',
                      style: theme.textTheme.ppMori700White12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

class DisplayItem {
  final SupportedDisplayBranch branch;
  final Function(BuildContext context, SupportedDisplayBranch branch)? onTap;

  DisplayItem({required this.branch, required this.onTap});

  Widget get logo => branch.logo;

  String get title => branch.title;
}
