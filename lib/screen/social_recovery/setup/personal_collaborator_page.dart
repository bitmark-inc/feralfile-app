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
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:share_plus/share_plus.dart';

class PersonalCollaboratorPage extends StatefulWidget {
  const PersonalCollaboratorPage({Key? key}) : super(key: key);

  @override
  State<PersonalCollaboratorPage> createState() => _PersonalCollaboratorPageState();
}

class _PersonalCollaboratorPageState extends State<PersonalCollaboratorPage> {
  final TextEditingController _textController = TextEditingController();

  bool _showDoneOption = false;
  bool _isProcessing = false;

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
              "Send your third recovery code to a trusted friend who can keep it safe. We recommend sending it through a secure messaging app like Signal.",
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
                    onPressed: () => shareShardDeck(),
                    child: Text(_showDoneOption ? "Shared" : "Share my recovery code"),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 40),
            // Row(
            //   children: [
            //     RoundCheckBox(
            //       size: 24.0,
            //       borderColor: theme.colorScheme.primary,
            //       uncheckedColor: theme.colorScheme.secondary,
            //       checkedColor: theme.colorScheme.primary,
            //       isChecked: true,
            //       checkedWidget: Icon(
            //         CupertinoIcons.checkmark,
            //         color: theme.colorScheme.secondary,
            //         size: 14,
            //       ),
            //       // checkedColor: Colors,
            //       onTap: (bool? value) {},
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //         child: Text(
            //       "I have shared my recovery code with:",
            //       //"I understand that this action cannot be undone.",
            //       style: theme.textTheme.bodyText1,
            //     )),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // AuTextField(
            //   title: "Enter a name to help you remember",
            //   controller: _textController,
            //   placeholder: "Personal collaborator",
            // ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "SAVE".toUpperCase(),
                    enabled: _showDoneOption,
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.recoverySetupDonePage);
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

  Future shareShardDeck() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      final secretFile =
      await injector<SocialRecoveryService>().getEmergencyContactDeck();
      setState(() {
        _isProcessing = false;
      });

      final result = await Share.shareFilesWithResult([secretFile]);

      // Handle when user shares or cancels the share dialog
      switch (result.status) {
        case ShareResultStatus.success:
          doneSetupEmergencyContact();
          setState(() {
            _showDoneOption = true;
          });
          break;
        case ShareResultStatus.unavailable:
          setState(() {
            _showDoneOption = true;
          });
          break;

        case ShareResultStatus.dismissed:
          break;
      }
    } catch (exception) {
      setState(() {
        _isProcessing = false;
      });
      rethrow;
    }
  }

  Future doneSetupEmergencyContact() async {
    await injector<SocialRecoveryService>().doneSetupEmergencyContact();
  }
}
