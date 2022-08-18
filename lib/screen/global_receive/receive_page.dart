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
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GlobalReceivePage extends StatefulWidget {
  const GlobalReceivePage({Key? key}) : super(key: key);
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
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
        final categorizedAccounts = state.categorizedAccounts;
        if (categorizedAccounts == null) {
          return Container(
            alignment: Alignment.center,
            child: loadingIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16.0),
              Text(
                "select_address_tt".tr(),
                style: theme.textTheme.headline1,
              ),
              const SizedBox(height: 40.0),
              Text(
                "select_address".tr(),
                //"Select an address on the appropriate blockchain where you want to receive your NFT or cryptocurrency:",
                style: theme.textTheme.bodyText1,
              ),
              const SizedBox(height: 24),
              ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: ((context, index) => Container(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        child: accountWithConnectionItem(
                            context, categorizedAccounts[index]),
                      )),
                  separatorBuilder: ((context, index) => addDivider(height: 0)),
                  itemCount: categorizedAccounts.length)
            ],
          ),
        );
      }),
    );
  }
}
