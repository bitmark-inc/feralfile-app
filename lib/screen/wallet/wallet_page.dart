//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/account/access_method_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

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
    unawaited(injector<SettingsDataService>().backup());
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
    unawaited(injector<SettingsDataService>().backup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _showAddWalletOption() {
    final transparentTextTheme = Theme.of(context)
        .textTheme
        .ppMori400FFYellow14
        .copyWith(color: Colors.transparent);
    final options = [
      OptionItem(
        title: 'create_a_new_wallet'.tr(),
        icon: SvgPicture.asset(
          'assets/images/joinFile.svg',
          colorFilter:
              const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          height: 24,
        ),
        onTap: () {
          unawaited(Navigator.of(context).pushNamed(AddressAlias.tag,
              arguments: AddressAliasPayload(WalletType.Autonomy)));
        },
      ),
      OptionItem(
        title: 'add_an_existing_wallet'.tr(),
        icon: Image.asset(
          'assets/images/icon_save.png',
          height: 24,
        ),
        onTap: () {
          unawaited(Navigator.of(context).popAndPushNamed(ImportSeedsPage.tag));
        },
      ),
      OptionItem(
        title: 'view_existing_address'.tr().toLowerCase().capitalize(),
        icon: SvgPicture.asset(
          'assets/images/unhide.svg',
          colorFilter:
              const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          height: 24,
        ),
        onTap: () {
          unawaited(Navigator.of(context).popAndPushNamed(
              ViewExistingAddress.tag,
              arguments: ViewExistingAddressPayload(false)));
        },
      ),
      OptionItem(
          title: 'debug_artwork',
          titleStyle: transparentTextTheme,
          onTap: () async {
            final debug = await isAppCenterBuild();
            if (debug && mounted) {
              unawaited(
                  Navigator.of(context).popAndPushNamed(AccessMethodPage.tag));
            }
          }),
    ];
    unawaited(UIHelper.showDrawerAction(context, options: options));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(context, title: 'addresses'.tr(), onBack: () {
          Navigator.of(context).pop();
        },
            icon: Semantics(
              label: 'address_menu',
              child: SvgPicture.asset(
                'assets/images/more_circle.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                    AppColor.primaryBlack, BlendMode.srcIn),
              ),
            ),
            action: _showAddWalletOption),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: ResponsiveLayout.pageEdgeInsetsWithSubmitButton.bottom,
            ),
            child: const Column(
              children: [
                SizedBox(height: 40),
                AccountsView(
                  isInSettingsPage: true,
                ),
              ],
            ),
          ),
        ),
      );
}
