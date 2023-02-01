//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class AuPrimaryButton extends StatelessWidget {
  final Function()? onPressed;
  final String text;

  const AuPrimaryButton({Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.auSuperTeal,
          disabledForegroundColor: AppColor.secondaryDimGreyBackground,
          disabledBackgroundColor: AppColor.secondaryDimGreyBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: Theme.of(context).textTheme.ppMori400Black14),
      ),
    );
  }
}

class AuSecondaryButton extends StatelessWidget {
  final Function() onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const AuSecondaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor ?? Colors.white),
            borderRadius: BorderRadius.circular(32.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .ppMori400White14
              .copyWith(color: textColor),
        ),
      ),
    );
  }
}

class AuCustomButton extends StatelessWidget {
  final Function()? onPressed;
  final Widget? child;

  const AuCustomButton({Key? key, required this.onPressed, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          side: const BorderSide(),
          alignment: Alignment.center,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
