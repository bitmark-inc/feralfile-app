//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with RouteAware, WidgetsBindingObserver {
  late PersonaBloc _personaBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AccountsBloc>().add(GetAccountsEvent());
    _personaBloc = context.read<PersonaBloc>();
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

  void _showAddWalletOption() {
    final options = [
      OptionItem(
        title: "create_a_new_wallet".tr(),
        icon: SvgPicture.asset(
          "assets/images/autonomy_icon_white.svg",
          color: AppColor.primaryBlack,
          height: 24,
        ),
        builder: (context, child) {
          return BlocProvider.value(
              value: _personaBloc,
              child: BlocConsumer<PersonaBloc, PersonaState>(
                listener: (context, state) {
                  switch (state.createAccountState) {
                    case ActionState.loading:
                      UIHelper.showLoadingScreen(context,
                          text: "generating_wallet".tr());
                      break;
                    case ActionState.done:
                      UIHelper.hideInfoDialog(context);
                      final createdPersona = state.persona;
                      if (createdPersona != null) {
                        Navigator.of(context).pushNamed(
                            AppRouter.namePersonaPage,
                            arguments: NamePersonaPayload(
                                uuid: createdPersona.uuid, allowBack: true));
                      }
                      break;

                    case ActionState.error:
                      UIHelper.hideInfoDialog(context);
                      break;
                    default:
                      break;
                  }
                },
                builder: (context, state) {
                  return GestureDetector(
                    child: child,
                    onTap: () {
                      if (_personaBloc.state.createAccountState ==
                          ActionState.loading) {
                        return;
                      }
                      _personaBloc.add(CreatePersonaEvent());
                    },
                  );
                },
              ));
        },
      ),
      OptionItem(
        title: "add_an_existing_wallet".tr(),
        icon: SvgPicture.asset(
          "assets/images/add_wallet.svg",
          height: 24,
        ),
        onTap: () {
          Navigator.of(context).popAndPushNamed(AppRouter.accessMethodPage);
        },
      ),
      OptionItem(),
    ];
    UIHelper.showDrawerAction(context, options: options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "wallets".tr(),
          onBack: null,
          icon: SvgPicture.asset(
            'assets/images/more_circle.svg',
            width: 22,
            color: AppColor.primaryBlack,
          ),
          action: _showAddWalletOption),
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
            ],
          ),
        ),
      ),
    );
  }
}
