//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';

class RestoreInstitutionalVerifyPage extends StatefulWidget {
  final dynamic payload;

  const RestoreInstitutionalVerifyPage({Key? key, this.payload})
      : super(key: key);

  @override
  State<RestoreInstitutionalVerifyPage> createState() =>
      _RestoreInstitutionalVerifyPageState();
}

class _RestoreInstitutionalVerifyPageState
    extends State<RestoreInstitutionalVerifyPage> {
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
              "Paste your recovery code from Feral File below.",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(height: 40),
            AuTextField(
              title: "Recovery link",
              controller: _textController,
              placeholder: "Paste recovery code here",
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "NEXT".toUpperCase(),
                    onPress: () => withDebounce(
                      () async {
                        late ShardDeck shardServiceDeck;
                        try {
                          shardServiceDeck = await injector<SocialRecoveryService>()
                              .requestDeckFromShardService(widget.payload?.domain ??
                                    Environment.autonomyShardService,
                                _textController.text,);
                        } catch (_) {
                          Navigator.of(context).pop();
                          rethrow;
                        }
                        await injector<ConfigurationService>().setCachedDeckFromShardService(shardServiceDeck);
                        await Future.delayed(SHOW_DIALOG_DURATION);

                        final hasPlatformShards = await injector<SocialRecoveryService>().hasPlatformShards();
                        if (hasPlatformShards) {
                          if (!mounted) return;
                          // try to restore from PlatformShards & ShardService's ShardDeck
                          UIHelper.showInfoDialog(context, "RESTORING...",
                              'Restoring your account with 2 shardDecks: Platform & ShardService');
                          // await Future.delayed(SHORT_SHOW_DIALOG_DURATION);

                          try {
                            await injector<SocialRecoveryService>().restoreAccountWithPlatformKey(shardServiceDeck);
                            if (!mounted) return;

                            doneOnboardingRestore(context);
                          } on SocialRecoveryMissingShard catch (_) {
                            Navigator.of(context).pop();
                            final theme = Theme.of(context);
                            UIHelper.showDialog(
                              context,
                              "Error",
                              Text("ShardDecks don't match.",
                                  style: theme.primaryTextTheme.bodyText1),
                              submitButton: AuFilledButton(
                                  text: 'RESTORE WITH EMERGENCY CONTACT',
                                  onPress: () => Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRouter.restoreWithEmergencyContactPage,
                                      (route) =>
                                          route.settings.name == AppRouter.onboardingPage)),
                              closeButton: 'CLOSE',
                            );
                          } catch (_) {
                            Navigator.of(context).pop();
                            rethrow;
                          }
                        } else {
                          // missing platformShards, ask EC's ShardDeck to restore
                          Navigator.of(context).pop();
                          await injector<NavigationService>()
                              .navigatorKey
                              .currentState
                              ?.pushNamedAndRemoveUntil(AppRouter.restoreWithEmergencyContactPage,
                                  (route) => route.settings.name == AppRouter.onboardingPage);
                        }



                        // await injector<SocialRecoveryService>()
                        //     .sendDeckToShardService(
                        //   widget.payload?.domain ??
                        //       Environment.autonomyShardService,
                        //   _textController.text,
                        // );
                        //
                        // if (!mounted) return;
                        // Navigator.of(context).pushNamedAndRemoveUntil(
                        //   AppRouter.personalCollaboratorPage,
                        //   (route) =>
                        //       route.settings.name == AppRouter.settingsPage ||
                        //       route.settings.name == AppRouter.homePage ||
                        //       route.settings.name ==
                        //           AppRouter.homePageNoTransition,
                        // );
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
