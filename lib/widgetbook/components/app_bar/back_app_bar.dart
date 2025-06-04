// ưwidgetbook for getBackAppBar

import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:widgetbook/widgetbook.dart';

final backAppBarComponent = WidgetbookComponent(
  name: 'BackAppBar',
  useCases: [
    WidgetbookUseCase(
      name: 'default',
      builder: useCaseGetBackAppBar,
    ),
  ],
);

Widget useCaseGetBackAppBar(BuildContext context) {
  final action = context.knobs.boolean(label: 'Action')
      ? SvgPicture.asset(
          'assets/images/more_circle.svg',
          width: 22,
          colorFilter: const ColorFilter.mode(
            AppColor.primaryBlack,
            BlendMode.srcIn,
          ),
        )
      : null;
  return getBackAppBar(
    context,
    onBack: context.knobs.boolean(
      label: 'Can go back',
      initialValue: true,
    )
        ? () {
            Navigator.of(context).pop();
          }
        : null,
    title: context.knobs.string(
      label: 'Title',
      initialValue: 'Back App Bar',
    ),
    actions: [
      if (action != null) action,
    ],
  );
}
