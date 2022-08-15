//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_view.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_view.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                          "Accounts",
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
                        '+ Account',
                        style: theme.textTheme.subtitle1,
                      ),
                    ),
                    const SizedBox(width: 13),
                  ],
                ),
                const SizedBox(height: 40),
                BlocProvider(
                  create: (_) => PreferencesBloc(
                      injector(), injector<NetworkConfigInjector>().I()),
                  child: const PreferenceView(),
                ),
                const SizedBox(height: 40.0),
                BlocProvider.value(
                  value: _upgradesBloc,
                  child: const UpgradesView(),
                ),
                const SizedBox(height: 40),
                Text(
                  "Networks",
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 24.0),
                _settingItem(
                    context,
                    "Select network",
                    injector<ConfigurationService>().getNetwork() ==
                            Network.TESTNET
                        ? "Test network"
                        : "Main network", () async {
                  await Navigator.of(context).pushNamed(SelectNetworkPage.tag);
                }),
                const SizedBox(height: 40.0),
                // START HELP US IMPROVE
                Text(
                  "Help us improve",
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 8.0),
                TappableForwardRow(
                    leftWidget: Text('Participate in bug bounty',
                        style: theme.textTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.bugBountyPage)),
                addOnlyDivider(),
                TappableForwardRow(
                    leftWidget: Text('Participate in a user test',
                        style: theme.textTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.participateUserTestPage)),
                // END HELP US IMPROVE
                const SizedBox(height: 40.0),
                Text(
                  "Data management",
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 24.0),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'Rebuild metadata',
                      style: theme.textTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'Clear local cache and re-download all artwork metadata.',
                        style: theme.textTheme.bodyText1),
                    onTap: () => _showRebuildGalleryDialog()),
                addDivider(),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'Forget I exist',
                      style: theme.textTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'Erase all information about me and delete my keys from my cloud backup including the keys on this device.',
                        style: theme.textTheme.bodyText1),
                    onTap: () => _showForgetIExistDialog()),
                const SizedBox(height: 56),
                Column(children: [
                  if (_packageInfo != null)
                    GestureDetector(
                        child: Text(
                          "Version ${_packageInfo!.version}(${_packageInfo!.buildNumber})",
                          key: const Key("version"),
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
                                  "Demo mode",
                                  "Demo mode ${newValue ? 'enabled' : 'disabled'}!",
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
                      child: Text("Release notes",
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

  Widget _settingItem(
      BuildContext context, String name, String value, Function() onTap) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: theme.textTheme.headline4,
            ),
            Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.subtitle1,
                ),
                const SizedBox(width: 8.0),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            )
          ],
        ),
      ),
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
      "Forget I exist",
      BlocProvider(
        create: (_) => ForgetExistBloc(
            injector(),
            injector(),
            injector(),
            injector(),
            injector(),
            injector<NetworkConfigInjector>().mainnetInjector(),
            injector<NetworkConfigInjector>().testnetInjector(),
            injector()),
        child: const ForgetExistView(),
      ),
    );
  }

  void _showRebuildGalleryDialog() {
    showErrorDialog(
      context,
      "Rebuild metadata",
      "This action will safely clear local cache and\nre-download all artwork metadata. We recommend only doing this if instructed to do so by customer support to resolve a problem.",
      "REBUILD",
      () async {
        await injector<TokensService>().purgeCachedGallery();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
      },
      "CANCEL",
    );
  }
}
