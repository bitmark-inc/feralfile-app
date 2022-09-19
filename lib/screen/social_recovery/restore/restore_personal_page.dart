//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestorePersonalPage extends StatefulWidget {
  const RestorePersonalPage({Key? key}) : super(key: key);

  @override
  State<RestorePersonalPage> createState() =>
      _RestorePersonalPageState();
}

class _RestorePersonalPageState extends State<RestorePersonalPage> {
  bool _showDoneOption = false;
  ShardDeck? _shardDeck;

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
              "STEP 3 OF 3",
              style: theme.textTheme.headline3,
            ),
            Text(
              "Personal collaborator",
              style: theme.textTheme.headline2,
            ),
            const SizedBox(height: 40),
            Text(
              "Ask your trusted friend to send you the third recovery code you asked them to keep for you. We recommend receiving it through a secure messaging app like Signal.",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      primary: theme.primaryColor,
                      textStyle: theme.textTheme.atlasDimgreyBold16
                          .copyWith(color: Colors.black),
                      side: const BorderSide(
                        width: 2.0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: const ContinuousRectangleBorder(),
                    ),
                    onPressed: () => pasteShareDeck(),
                    child: Text(
                        _showDoneOption ? "Pasted" : "Paste my recovery code"),
                  ),
                ),
              ],
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "SAVE".toUpperCase(),
                    enabled: _showDoneOption,
                    onPress: () async {
                      final shardDeck = _shardDeck!;
                      try {
                        final shardServiceDeck =
                            injector<ConfigurationService>()
                                .getCachedDeckFromShardService();
                        var runRestoreAccountWithPlatformKey = true;

                        if (shardServiceDeck != null) {
                          UIHelper.showInfoDialog(context, "RESTORING...",
                              'Restoring your account with 2 shardDecks: Shard Service & Contact');
                          try {
                            await injector<SocialRecoveryService>()
                                .restoreAccount(shardServiceDeck, shardDeck);
                            runRestoreAccountWithPlatformKey = false;
                          } catch (_) {}
                        }

                        if (runRestoreAccountWithPlatformKey) {
                          if (!mounted) return;
                          UIHelper.showInfoDialog(context, "RESTORING...",
                              'Restoring your account with 2 shardDecks: Platform & Contact');
                          await injector<SocialRecoveryService>()
                              .restoreAccountWithPlatformKey(shardDeck);
                        }

                        doneOnboardingRestore(context);
                      } catch (exception) {
                        UIHelper.showInfoDialog(
                          context,
                          "Error",
                          "ShardDecks don't match. Please check again",
                          closeButton: "CLOSE",
                          isDismissible: true,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future pasteShareDeck() async {
    ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);

    if (cdata?.text == null) return;

    try {
      _shardDeck = ShardDeck.fromJson(jsonDecode(cdata!.text!));
      setState(() {
        _showDoneOption = true;
      });
    } catch (e) {
      //ignore
      print("Shard Errors: ${cdata?.text}");
    }
  }
}
