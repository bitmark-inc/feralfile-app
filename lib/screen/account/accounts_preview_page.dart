//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsPreviewPage extends StatefulWidget {
  const AccountsPreviewPage({Key? key}) : super(key: key);

  @override
  State<AccountsPreviewPage> createState() => _AccountsPreviewPageState();
}

class _AccountsPreviewPageState extends State<AccountsPreviewPage> {
  @override
  void initState() {
    super.initState();

    context.read<AccountsBloc>().add(GetAccountsEvent());
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
        margin: const EdgeInsets.only(
            top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "accounts".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    const SizedBox(height: 24),
                    const AccountsView(isInSettingsPage: false),
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
                        text: "link_another_account".tr().toUpperCase(),
                        onPress: () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.linkAccountpage);
                        },
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => doneOnboarding(context),
                  child: Text("done".tr(), style: theme.textTheme.button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
