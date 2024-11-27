//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, this.payload});

  final WalletPagePayload? payload;

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
    WidgetsBinding.instance.addPostFrameCallback((context) {
      if (widget.payload?.openAddAddress == true) {
        _showAddWalletOption();
      }
    });
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
        title: 'view_existing_address'.tr().toLowerCase().capitalize(),
        icon: SvgPicture.asset(
          'assets/images/unhide.svg',
          height: 24,
        ),
        onTap: () {
          unawaited(
            Navigator.of(context).popAndPushNamed(
              AppRouter.viewExistingAddressPage,
              arguments: ViewExistingAddressPayload(false),
            ),
          );
        },
      ),
      OptionItem(
        title: 'debug_artwork',
        titleStyle: transparentTextTheme,
        onTap: () async {
          final debug = await isAppCenterBuild();
          if (debug && mounted) {
            unawaited(
              Navigator.of(context).popAndPushNamed(AppRouter.accessMethodPage),
            );
          }
        },
      ),
    ];
    unawaited(UIHelper.showDrawerAction(context, options: options));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'wallet'.tr(),
          onBack: () {
            Navigator.of(context).pop();
          },
          icon: Semantics(
            label: 'address_menu',
            child: SvgPicture.asset(
              'assets/images/more_circle.svg',
              width: 22,
              colorFilter: const ColorFilter.mode(
                AppColor.primaryBlack,
                BlendMode.srcIn,
              ),
            ),
          ),
          action: _showAddWalletOption,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveLayout.pageEdgeInsetsWithSubmitButton.bottom,
            ),
            child: const AccountsView(
              isInSettingsPage: true,
            ),
          ),
        ),
      );
}

class WalletPagePayload {
  const WalletPagePayload({required this.openAddAddress});

  final bool openAddAddress;
}
