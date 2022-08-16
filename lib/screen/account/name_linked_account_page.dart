//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NameLinkedAccountPage extends StatefulWidget {
  final Connection connection;

  const NameLinkedAccountPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<NameLinkedAccountPage> createState() => _NameLinkedAccountPageState();
}

class _NameLinkedAccountPageState extends State<NameLinkedAccountPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_nameController.text.isEmpty) {
      _nameController.text = widget.connection.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: Container(
        margin:
            const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account alias",
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "You can add an optional alias for this account to help you recognize it. This alias will only be visible to you in Autonomy.",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    AuTextField(
                        title: "",
                        placeholder: "Enter alias",
                        controller: _nameController),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "SAVE ALIAS".toUpperCase(),
                        onPress: () {
                          context.read<AccountsBloc>().add(
                              NameLinkedAccountEvent(
                                  widget.connection, _nameController.text));
                          _doneNaming();
                        },
                      ),
                    ),
                  ],
                ),
                TextButton(
                    onPressed: () {
                      _doneNaming();
                    },
                    child: Text("SKIP", style: theme.textTheme.button)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _doneNaming() {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRouter.settingsPage);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.accountsPreviewPage, (route) => false);
    }
  }
}
