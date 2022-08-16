//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class LinkManuallyPage extends StatefulWidget {
  final String type;
  const LinkManuallyPage({required this.type, Key? key}) : super(key: key);

  @override
  State<LinkManuallyPage> createState() => _LinkManuallyPageState();
}

class _LinkManuallyPageState extends State<LinkManuallyPage> {
  final TextEditingController _addressController = TextEditingController();

  String get title {
    switch (widget.type) {
      case 'address':
        return 'Link Address';
      case 'indexerTokenID':
        return 'Indexer TokenID';
      default:
        return '';
    }
  }

  String get description {
    switch (widget.type) {
      case 'address':
        return 'To manually input an address (Debug only).';
      case 'indexerTokenID':
        return 'To manually input an indexer TokenID (Debug only).';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      description,
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    AuTextField(
                      title: "",
                      placeholder: "Paste ${widget.type}",
                      controller: _addressController,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "LINK".toUpperCase(),
                    onPress: () => _link(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _link() async {
    switch (widget.type) {
      case 'address':
        await injector<AccountService>()
            .linkManuallyAddress(_addressController.text);
        if (!mounted) return;
        UIHelper.showInfoDialog(
            context, 'Account linked', 'Autonomy has linked your address.');
        break;

      case 'indexerTokenID':
        await injector<AccountService>()
            .linkIndexerTokenID(_addressController.text);
        if (!mounted) return;
        UIHelper.showInfoDialog(
            context, 'Account linked', 'Autonomy has linked your address.');
        break;

      default:
        return;
    }

    Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name == AppRouter.settingsPage);
      } else {
        doneOnboarding(context);
      }
    });
  }
}
