import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

class LoadingWidget extends StatelessWidget {
  final bool invertColors;
  final Color? backgroundColor;

  const LoadingWidget(
      {super.key, this.invertColors = false, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: backgroundColor ?? AppColor.primaryBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GifView.asset(
              'assets/images/loading_white.gif',
              height: 52,
              frameRate: 12,
              invertColors: invertColors,
            ),
            const SizedBox(height: 12),
            Text(
              'loading'.tr(),
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori400White12
                  : theme.textTheme.ppMori400White14,
            )
          ],
        ),
      ),
    );
  }
}
