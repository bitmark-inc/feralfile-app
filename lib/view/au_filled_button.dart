//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class AuFilledButton extends StatelessWidget {
  final String text;
  final Function()? onPress;
  final Color color;
  final bool enabled;
  final Widget? icon;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final bool isProcessing;

  const AuFilledButton(
      {Key? key,
      required this.text,
      required this.onPress,
      this.icon,
      this.enabled = true,
      this.color = AppColor.primaryBlack,
      this.isProcessing = false,
      this.textStyle,
      this.textAlign})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? color : color.withOpacity(0.6),
            disabledForegroundColor: color.withOpacity(0.38),
            disabledBackgroundColor: color.withOpacity(0.12),
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(),
            splashFactory:
                enabled ? InkRipple.splashFactory : NoSplash.splashFactory,
            padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: enabled ? onPress : () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isProcessing
                ? Container(
                    height: 14.0,
                    width: 14.0,
                    margin: const EdgeInsets.only(right: 8.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      strokeWidth: 2.0,
                    ),
                  )
                : const SizedBox(),
            icon != null
                ? Container(
                    margin: const EdgeInsets.only(right: 8.0), child: icon!)
                : const SizedBox(),
            Text(
              text.toUpperCase(),
              style: textStyle ?? theme.primaryTextTheme.button,
              textAlign: textAlign,
            ),
          ],
        ),
      ),
    );
  }
}
