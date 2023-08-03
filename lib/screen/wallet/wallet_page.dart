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
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/choose_chain_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/carousel.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tip_card.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with RouteAware, WidgetsBindingObserver {
  /// please increase addressWhatNewVersion when update the content of tip card
  /// to show the tip card again
  static const int addressWhatNewVersion = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<SettingsDataService>().backup();
    _checkTipCardShowTime();
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
          "assets/images/joinFile.svg",
          color: AppColor.primaryBlack,
          height: 24,
        ),
        onTap: () {
          Navigator.of(context).popAndPushNamed(ChooseChainPage.tag);
        },
      ),
      OptionItem(
        title: "add_an_existing_wallet".tr(),
        icon: SvgPicture.asset(
          "assets/images/icon_save.svg",
          color: AppColor.primaryBlack,
          height: 24,
        ),
        onTap: () {
          Navigator.of(context).popAndPushNamed(ImportSeedsPage.tag);
        },
      ),
      OptionItem(
        title: "view_existing_address".tr().toLowerCase().capitalize(),
        icon: SvgPicture.asset(
          "assets/images/unhide.svg",
          color: AppColor.primaryBlack,
          height: 24,
        ),
        onTap: () {
          Navigator.of(context).popAndPushNamed(ViewExistingAddress.tag,
              arguments: ViewExistingAddressPayload(false));
        },
      ),
      OptionItem(
        onTap: () async {
          final debug = await isAppCenterBuild();
          if (debug && mounted) {
            Navigator.of(context).popAndPushNamed(AppRouter.accessMethodPage);
          }
        },
      ),
    ];
    UIHelper.showDrawerAction(context, options: options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "addresses".tr(),
          onBack: null,
          icon: Semantics(
            label: "address_menu",
            child: SvgPicture.asset(
              'assets/images/more_circle.svg',
              width: 22,
              color: AppColor.primaryBlack,
            ),
          ),
          action: _showAddWalletOption),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: ResponsiveLayout.pageEdgeInsetsWithSubmitButton.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _carouselTipcard(context),
              const SizedBox(height: 20),
              const AccountsView(
                isInSettingsPage: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carouselTipcard(BuildContext context) {
    final configurationService = injector<ConfigurationService>();
    return MultiValueListenableBuilder(
      valueListenables: [configurationService.showWhatNewAddressTip],
      builder: (BuildContext context, List<dynamic> values, Widget? child) {
        return CarouselWithIndicator(
          items: _listTipCards(context, values),
        );
      },
    );
  }

  List<Tipcard> _listTipCards(BuildContext context, List<dynamic> values) {
    final isShowWhatNew = values[0] as bool;
    final configurationService = injector<ConfigurationService>();
    return [
      if (isShowWhatNew)
        Tipcard(
            titleText: "what_new".tr(),
            onClosed: () {
              configurationService
                  .setShowWhatNewAddressTipRead(addressWhatNewVersion);
            },
            content: Markdown(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              data: "address_what_new".tr(),
              softLineBreak: true,
              styleSheet: markDownStyleTipCard(context),
              padding: const EdgeInsets.all(0),
            ),
            listener: configurationService.showWhatNewAddressTip),
    ];
  }

  Future<void> _checkTipCardShowTime() async {
    final configurationService = injector<ConfigurationService>();
    final isShowWhatNew =
        configurationService.getShowWhatNewAddressTip(addressWhatNewVersion);
    configurationService.showWhatNewAddressTip.value = isShowWhatNew;
  }
}
