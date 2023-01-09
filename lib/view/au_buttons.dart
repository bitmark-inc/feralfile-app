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

  const AuSecondaryButton(
      {Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(32.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: Theme.of(context).textTheme.ppMori400White14),
      ),
    );
  }
}
