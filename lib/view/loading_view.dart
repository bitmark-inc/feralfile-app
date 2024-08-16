import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/extensions.dart';
import 'package:flutter/material.dart';

Widget loadingView(BuildContext context, {double size = 52.0}) {
  final theme = Theme.of(context);
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        'assets/images/loading.gif',
        width: size,
        height: size,
      ),
      const SizedBox(height: 20),
      Text(
        'h_loading...'.tr(),
        style: theme.textTheme.ppMori400White14,
      )
    ],
  );
}
