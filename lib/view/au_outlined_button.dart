//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class AuOutlinedButton extends StatelessWidget {
  final String text;
  final Function() onPress;

  const AuOutlinedButton({Key? key, required this.text, required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ClipPath(
          clipper: AutonomyOutlineButtonClipper(),
          child: Container(
              width: double.infinity,
              height: 48,
              color: theme.colorScheme.primary),
        ),
        SizedBox(
          width: double.infinity,
          child: ClipPath(
              clipper: AutonomyButtonClipper(),
              child: TextButton(
                style: TextButton.styleFrom(
                    primary: theme.colorScheme.primary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: onPress,
                child: Text(
                  text.toUpperCase(),
                  style: theme.textTheme.button,
                ),
              )),
        ),
      ],
    );
  }
}
