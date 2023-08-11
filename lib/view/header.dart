//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeaderView extends StatelessWidget {
  final double paddingTop;
  final bool isWhite;
  final Widget? action;

  const HeaderView(
      {Key? key, required this.paddingTop, this.isWhite = false, this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, paddingTop, 0, 40),
        child: Column(
          children: [
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
}

class AutonomyLogo extends StatelessWidget {
  final bool isWhite;

  const AutonomyLogo({Key? key, this.isWhite = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pair<bool, bool>>(
        future: logoState(),
        builder: (context, snapshot) {
          if (snapshot.data == null) return const SizedBox(height: 50);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                isWhite
                    ? "assets/images/autonomy_icon_white.svg"
                    : snapshot.data!.first == true
                        ? "assets/images/logo_dev.svg"
                        : "assets/images/penrose_moma.svg",
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 15),
              snapshot.data!.second
                  ? proLabel(Theme.of(context), isWhite: isWhite)
                  : const SizedBox(),
            ],
          );
        });
  }

  Widget proLabel(ThemeData theme, {bool isWhite = false}) {
    final color = isWhite ? AppColor.white : AppColor.primaryBlack;
    return GestureDetector(
      onTap: () {
        final context =
            injector<NavigationService>().navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).pushNamed(AppRouter.subscriptionPage);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
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
      ),
    );
  }
}
