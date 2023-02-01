//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<SettingsDataService>().backup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<SettingsDataService>().backup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return Scaffold(
      appBar: getBackAppBar(context, title: "wallets".tr(), onBack: () {
        Navigator.of(context).pop();
      }),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: ResponsiveLayout.pageEdgeInsetsWithSubmitButton.bottom,
          ),
          child: Column(
            children: [
              addTitleSpace(),
              const AccountsView(
                isInSettingsPage: true,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: padding,
                child: PrimaryButton(
                  text: 'add_wallet'.tr(),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.accessMethodPage);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
