//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeaderView extends StatelessWidget {
  final double paddingTop;
  final bool isWhite;
  final Widget? action;

  const HeaderView(
      {required this.paddingTop, super.key, this.isWhite = false, this.action});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.fromLTRB(0, paddingTop, 0, 40),
          child: Column(
            children: [
              headDivider(),
              const SizedBox(height: 7),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: AutonomyLogo(
                      isWhite: isWhite,
                    ),
                  ),
                  const Spacer(),
                  action ?? const SizedBox()
                ],
              ),
            ],
          ),
        ),
      );
}

class AutonomyLogo extends StatelessWidget {
  final bool isWhite;

  const AutonomyLogo({super.key, this.isWhite = false});

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
      // ignore: discarded_futures
      future: logoState(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const SizedBox(height: 50);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              isWhite
                  ? 'assets/images/autonomy_icon_white.svg'
                  : snapshot.data!
                      ? 'assets/images/logo_dev.svg'
                      : 'assets/images/penrose_moma.svg',
              width: 50,
              height: 50,
            ),
          ],
        );
      });
}
