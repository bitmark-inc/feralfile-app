//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_view.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_view.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with RouteAware, WidgetsBindingObserver {
  PackageInfo? _packageInfo;
  late ScrollController _controller;
  late final UpgradesBloc _upgradesBloc = UpgradesBloc(injector(), injector());
  int _lastTap = 0;
  int _consecutiveTaps = 0;
  var _forceAccountsViewRedraw;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPackageInfo();
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<SettingsDataService>().backup();
    _controller = ScrollController();
    _forceAccountsViewRedraw = Object();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<SettingsDataService>().backup();
    setState(() {
      _forceAccountsViewRedraw = Object();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
          body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            controller: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 72, 0, 45),
                    child: autonomyLogo,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "accounts".tr(),
                          style: theme.textTheme.headline1,
                        ),
                        _cloudAvailabilityWidget(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AccountsView(
                        key: ValueKey(_forceAccountsViewRedraw),
                        isInSettingsPage: true),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRouter.addAccountPage),
                      child: Text(
                        'plus_account'.tr(),
                        style: theme.textTheme.subtitle1,
                      ),
                    ),
                    const SizedBox(width: 13),
                  ],
                ),
                const SizedBox(height: 40),
                BlocProvider(
                  create: (_) => PreferencesBloc(injector()),
                  child: const PreferenceView(),
                ),
                const SizedBox(height: 40.0),
                BlocProvider.value(
                  value: _upgradesBloc,
                  child: const UpgradesView(),
                ),
                const SizedBox(height: 40),
                // START HELP US IMPROVE
                Text(
                  "help_us_improve".tr(),
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 16.0),
                TappableForwardRow(
                    leftWidget: Text('p_bug_bounty'.tr(),
                        style: theme.textTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.bugBountyPage)),
                addOnlyDivider(),
                TappableForwardRow(
                    leftWidget: Text('p_user_test'.tr(),
                        style: theme.textTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.participateUserTestPage)),
                // END HELP US IMPROVE
                const SizedBox(height: 40.0),
                Text(
                  "data_management".tr(),
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 32.0),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'rebuild_metadata'.tr(),
                      style: theme.textTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'clear_cache'.tr(),
                        style: theme.textTheme.bodyText1),
                    onTap: () => _showRebuildGalleryDialog()),
                addDivider(),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'forget_exist'.tr(),
                      style: theme.textTheme.headline4,
                    ),
                    bottomWidget: Text(
                        "erase_all".tr(),
                        //'Erase all information about me and delete my keys from my cloud backup including the keys on this device.',
                        style: theme.textTheme.bodyText1),
                    onTap: () => _showForgetIExistDialog()),
                const SizedBox(height: 56),
                Column(children: [
                  if (_packageInfo != null)
                    GestureDetector(
                        child: Text(
                          "version_".tr(namedArgs: {"version":_packageInfo!.version,"buildNumber":_packageInfo!.buildNumber}),
                          //"Version ${_packageInfo!.version}(${_packageInfo!.buildNumber})",
                          style: theme.textTheme.headline5,
                        ),
                        onTap: () async {
                          int now = DateTime.now().millisecondsSinceEpoch;
                          if (now - _lastTap < 1000) {
                            _consecutiveTaps++;
                            if (_consecutiveTaps == 3) {
                              final newValue =
                                  await injector<ConfigurationService>()
                                      .toggleDemoArtworksMode();
                              if (!mounted) return;
                              await UIHelper.showInfoDialog(
                                  context,
                                  "demo_mode".tr(),
                                  "demo_mode_en".tr(args: [newValue ? "enable".tr() : "disable".tr()]),
                                  //"Demo mode ${newValue ? 'enabled' : 'disabled'}!",
                                  autoDismissAfter: 1);
                            }
                          } else {
                            _consecutiveTaps = 0;
                          }
                          _lastTap = now;
                        }),
                  TextButton(
                      onPressed: () => injector<VersionService>()
                          .showReleaseNotes(onlyWhenUnread: false),
                      child: Text("release_notes".tr(),
                          style: theme.textTheme.linkStyle2)),
                  const SizedBox(height: 10),
                  eulaAndPrivacyView(context),
                ]),
                const SizedBox(height: 60),
              ],
            ),
          ),
          PenroseTopBarView(
            _controller,
            PenroseTopBarViewStyle.settings,
          ),
        ],
      )),
    );
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _cloudAvailabilityWidget() {
    return ValueListenableBuilder<bool>(
        valueListenable: injector<CloudService>().isAvailableNotifier,
        builder: (BuildContext context, bool isAvailable, Widget? child) {
          if (isAvailable) {
            return const SizedBox();
          } else {
            return IconButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRouter.cloudPage, arguments: "settings"),
              icon: SvgPicture.asset("assets/images/iconCloudOff.svg"),
            );
          }
        });
  }

  void _showForgetIExistDialog() {
    UIHelper.showDialog(
      context,
      "forget_exit".tr(),
      BlocProvider(
        create: (_) => ForgetExistBloc(injector(), injector(), injector(),
            injector(), injector(), injector(), injector()),
        child: const ForgetExistView(),
      ),
    );
  }

  void _showRebuildGalleryDialog() {
    showErrorDialog(
      context,
      "rebuild_metadata".tr(),
      "this_action_clear".tr(),
      //"This action will safely clear local cache and\nre-download all artwork metadata. We recommend only doing this if instructed to do so by customer support to resolve a problem.",
      "rebuild".tr(),
      () async {
        await injector<NftCollectionBloc>()
            .tokensService
            .purgeCachedGallery();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
      },
      "cancel".tr(),
    );
  }
}
