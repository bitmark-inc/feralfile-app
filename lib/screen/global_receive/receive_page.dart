//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GlobalReceivePage extends StatefulWidget {
  final Function()? onClose;

  const GlobalReceivePage({
    super.key,
    this.onClose,
  });

  @override
  State<GlobalReceivePage> createState() => _GlobalReceivePageState();
}

class _GlobalReceivePageState extends State<GlobalReceivePage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountsBloc>().add(GetCategorizedAccountsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getCloseAppBar(
        context,
        title: 'select_wallet_tt'.tr(),
        onClose: widget.onClose,
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
        final categorizedAccounts = state.accounts;
        if (categorizedAccounts == null) {
          return Container(
            alignment: Alignment.center,
            child: loadingIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Padding(
                padding: ResponsiveLayout.pageEdgeInsets,
                child: Text(
                  'select_address'.tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: accountWithConnectionItem(
                            context, categorizedAccounts[index]),
                      ),
                  itemCount: categorizedAccounts.length),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }
}
