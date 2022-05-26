//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({Key? key}) : super(key: key);

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  TextEditingController _phraseTextController = TextEditingController();

  bool isError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Import account",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "Importing your account will also add support for all chains featured in Autonomy. We will automatically back up your account in your iCloud Keychain.",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 16),
                    learnMoreAboutAutonomySecurityWidget(context),
                    SizedBox(height: 40),
                    Container(
                      height: 120,
                      child: Column(
                        children: [
                          AuTextField(
                            title: "",
                            placeholder:
                                "Enter recovery phrase with each word separated by a space",
                            keyboardType: TextInputType.multiline,
                            expanded: true,
                            maxLines: null,
                            hintMaxLines: 2,
                            controller: _phraseTextController,
                            isError: isError,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONFIRM".toUpperCase(),
                    onPress: () => _import(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future _import() async {
    try {
      setState(() {
        isError = false;
      });

      final persona = await injector<AccountService>()
          .importPersona(_phraseTextController.text);
      // SideEffect: pre-fetch tokens
      injector<TokensService>().fetchTokensForAddresses([
        (await persona.wallet().getETHEip55Address()),
        (await persona.wallet().getTezosWallet()).address,
        (await persona.wallet().getBitmarkAddress()),
      ]);

      Navigator.of(context)
          .popAndPushNamed(AppRouter.namePersonaPage, arguments: persona.uuid);
    } catch (_) {
      UIHelper.hideInfoDialog(context);
      setState(() {
        isError = true;
      });
    }
  }
}
