//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';

class AuFilledButton extends StatelessWidget {
  final String text;
  final Function()? onPress;
  final Color color;
  final bool enabled;
  final Widget? icon;
  final TextStyle? textStyle;
  final bool isProcessing;

  const AuFilledButton(
      {Key? key,
      required this.text,
      required this.onPress,
      this.icon,
      this.enabled = true,
      this.color = Colors.black,
      this.isProcessing = false,
      this.textStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: enabled ? color : color.withOpacity(0.6),
            onSurface: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            splashFactory:
                enabled ? InkRipple.splashFactory : NoSplash.splashFactory,
            padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isProcessing
                ? Container(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      backgroundColor: Colors.grey,
                      strokeWidth: 2.0,
                    ),
                    height: 14.0,
                    width: 14.0,
                    margin: EdgeInsets.only(right: 8.0),
                  )
                : SizedBox(),
            icon != null
                ? Container(child: icon!, margin: EdgeInsets.only(right: 8.0))
                : SizedBox(),
            Text(
              text.toUpperCase(),
              style: textStyle ?? appTextTheme.button,
            ),
          ],
        ),
        onPressed: enabled ? onPress : () {},
      ),
    );
  }

  AuFilledButton copyWith({
    String? text,
    Function()? onPress,
    Color? color,
    bool? enabled,
    Widget? icon,
    TextStyle? textStyle,
    bool? isProcessing,
  }) {
    return AuFilledButton(
      text: text ?? this.text,
      onPress: onPress ?? this.onPress,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      textStyle: textStyle ?? this.textStyle,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
