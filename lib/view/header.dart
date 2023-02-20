//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeaderView extends StatelessWidget {
  final double paddingTop;
  final bool isWhite;

  const HeaderView({Key? key, required this.paddingTop, this.isWhite = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, paddingTop, 0, 40),
        child: Column(
          children: [
            headDivider(),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: isWhite ? autonomyWhiteLogo : autonomyLogo,
            ),
          ],
        ),
      ),
    );
  }
}

Widget get autonomyLogo {
  return FutureBuilder<Pair<bool, bool>>(
      future: logoState(),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox(height: 50);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              snapshot.data!.first == true
                  ? "assets/images/logo_dev.svg"
                  : "assets/images/penrose_moma.svg",
              width: 50,
            ),
            const SizedBox(width: 15),
            snapshot.data!.second
                ? proLabel(Theme.of(context))
                : const SizedBox(),
          ],
        );
      });
}

class AuWhiteLogo extends StatelessWidget {
  const AuWhiteLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return autonomyWhiteLogo;
  }
}

Widget get autonomyWhiteLogo {
  return FutureBuilder<bool>(
      future: isPremium(),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox(height: 50);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              "assets/images/autonomy_icon_white.svg",
              width: 50,
              height: 50,
            ),
            const SizedBox(width: 15),
            snapshot.data!
                ? proLabel(Theme.of(context), isWhite: true)
                : const SizedBox(),
          ],
        );
      });
}

Widget proLabel(ThemeData theme, {bool isWhite = false}) {
  final color = isWhite ? AppColor.white : AppColor.primaryBlack;
  return Container(
    decoration: BoxDecoration(
      border: Border.all(width: 2, color: color),
      color: Colors.transparent,
      borderRadius: BorderRadiusGeometry.lerp(
          const BorderRadius.all(Radius.circular(25)),
          const BorderRadius.all(Radius.circular(25)),
          5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "pro".tr().toUpperCase(),
            style: theme.textTheme.ppMori700White12.copyWith(color: color),
          ),
        ],
      ),
    ),
  );
}
