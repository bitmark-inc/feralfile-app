//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

class RestorePlatformPage extends StatefulWidget {
  const RestorePlatformPage({Key? key}) : super(key: key);

  @override
  State<RestorePlatformPage> createState() => _RestorePlatformPageState();
}

class _RestorePlatformPageState extends State<RestorePlatformPage> {

  bool? isHavingPlatformShard;

  @override
  void initState() {
    super.initState();
  }

  Future checkPlatformShard() async {
    final hasPlatformShards = await injector<SocialRecoveryService>().hasPlatformShards();
    setState(() {
      isHavingPlatformShard = hasPlatformShards;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getTrailingCloseAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STEP 1 OF 3",
              style: theme.textTheme.headline3,
            ),
            Text(
              "Platform collaborator",
              style: theme.textTheme.headline2,
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                const Icon(CupertinoIcons.check_mark),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    "Great news! We retrieved your recovery code from Apple. ",
                    maxLines: 2,
                    style: theme.textTheme.bodyText1,
                  ),
                ),
              ],
            ),
            const Expanded(child: SizedBox()),
            Center(
              child: SvgPicture.asset("assets/images/icloudKeychainGuide.svg"),
            ),
            const SizedBox(height: 32),
            isHavingPlatformShard == null ? const SizedBox() : isHavingPlatformShard! ? Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "NEXT".toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.restoreInstitutionalPage);
                    },
                  ),
                ),
              ],
            ) : Column(
              children: [
                AuFilledButton(
                  onPress: () => openAppSettings(),
                  text: "TRY A DIFFERENT ICLOUD ACCOUNT",
                ),
                TextButton(
                  child: Text(
                    "CONTINUE WITHOUT PLATFORM CODE",
                    style: theme.textTheme.button,
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRouter.restoreInstitutionalPage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
