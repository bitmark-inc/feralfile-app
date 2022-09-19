//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';

class RecoveryInstitutionalVerifyPage extends StatefulWidget {
  final dynamic payload;

  const RecoveryInstitutionalVerifyPage({Key? key, this.payload})
      : super(key: key);

  @override
  State<RecoveryInstitutionalVerifyPage> createState() =>
      _RecoveryInstitutionalVerifyPageState();
}

class _RecoveryInstitutionalVerifyPageState
    extends State<RecoveryInstitutionalVerifyPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.payload != null) {
      _textController.text = widget.payload.code;
    }
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
              "STEP 2 OF 3",
              style: theme.textTheme.headline3,
            ),
            Text(
              "Institutional collaborator",
              style: theme.textTheme.headline2,
            ),
            const SizedBox(height: 40),
            Text(
              "Feral File works with curators, artists, and institutions to explore new ways of exhibiting and collecting digital art. As a trusted institutional collaborator, Feral File will safely keep your second recovery code.",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(height: 40),
            AuTextField(
              title: "Verification code",
              controller: _textController,
              placeholder: "Input recovery code",
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE TO STEP 3".toUpperCase(),
                    onPress: () => withDebounce(
                      () async {
                        await injector<SocialRecoveryService>()
                            .sendDeckToShardService(
                          widget.payload?.domain ??
                              Environment.autonomyShardService,
                          _textController.text,
                        );

                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRouter.personalCollaboratorPage,
                          (route) =>
                              route.settings.name == AppRouter.settingsPage ||
                              route.settings.name == AppRouter.homePage ||
                              route.settings.name ==
                                  AppRouter.homePageNoTransition,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecoveryVerifyPayload {
  final String code;
  final String domain;

  RecoveryVerifyPayload(this.code, this.domain);
}
