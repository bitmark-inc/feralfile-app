//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class SetupEmergencyContactPage extends StatefulWidget {
  const SetupEmergencyContactPage({Key? key}) : super(key: key);

  @override
  State<SetupEmergencyContactPage> createState() =>
      _SetupEmergencyContactPageState();
}

class _SetupEmergencyContactPageState extends State<SetupEmergencyContactPage> {
  bool _showDoneOption = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Setup Emergency Contact",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "some description about Emergency Contact",
                      style: appTextTheme.bodyText1,
                    ),
                  ]),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "SHARE".toUpperCase(),
                      onPress: () => shareShardDeck(),
                    ),
                  ),
                ],
              ),
              if (_showDoneOption) ...[
                TextButton(
                  onPressed: () => doneSetupEmergencyContact(),
                  child: Text(
                    "DONE",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                  ),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }

  Future shareShardDeck() async {
    try {
      final secretFile =
          await injector<SocialRecoveryService>().getEmergencyContactDeck();
      final result = await Share.shareFilesWithResult([secretFile]);

      // Handle when user shares or cancels the share dialog
      switch (result.status) {
        case ShareResultStatus.success:
          doneSetupEmergencyContact();
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
      rethrow;
    }
  }

  Future doneSetupEmergencyContact() async {
    await injector<SocialRecoveryService>().doneSetupEmergencyContact();
    Navigator.of(context).pop();
  }
}
