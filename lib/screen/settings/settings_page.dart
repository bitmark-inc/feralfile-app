//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

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
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
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
    injector<SocialRecoveryService>().refreshSetupStep();
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
    injector<SocialRecoveryService>().refreshSetupStep();
    injector<SettingsDataService>().backup();
    setState(() {
      _forceAccountsViewRedraw = Object();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
          body: Stack(
        fit: StackFit.loose,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15),
            controller: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    child: autonomyLogo,
                    padding: EdgeInsets.fromLTRB(0, 72, 0, 45),
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
                          style: appTextTheme.headline1,
                        ),
                        _cloudAvailabilityWidget(),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                        'Autonomy accounts are full, multi-chain accounts. Linked accounts link to single-chain accounts from other wallets.',
                        style: appTextTheme.bodyText1),
                    SizedBox(height: 16),
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
                        child: Text('+ Account',
                            style: appTextTheme.bodyText2
                                ?.copyWith(color: Colors.black))),
                    SizedBox(width: 13),
                  ],
                ),

                _socialRecoveryWidget(),

                SizedBox(height: 40),
                BlocProvider(
                  create: (_) => PreferencesBloc(
                      injector(), injector<NetworkConfigInjector>().I()),
                  child: PreferenceView(),
                ),
                SizedBox(height: 40.0),
                BlocProvider.value(
                  value: _upgradesBloc,
                  child: UpgradesView(),
                ),
                SizedBox(height: 40),
                Text(
                  "Networks",
                  style: appTextTheme.headline1,
                ),
                SizedBox(height: 24.0),
                _settingItem(
                    context,
                    "Select network",
                    injector<ConfigurationService>().getNetwork() ==
                            Network.TESTNET
                        ? "Test network"
                        : "Main network", () async {
                  await Navigator.of(context).pushNamed(SelectNetworkPage.tag);
                }),
                SizedBox(height: 40.0),
                // START HELP US IMPROVE
                Text(
                  "Help us improve",
                  style: appTextTheme.headline1,
                ),
                SizedBox(height: 8.0),
                TappableForwardRow(
                    leftWidget: Text('Participate in bug bounty',
                        style: appTextTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.bugBountyPage)),
                addOnlyDivider(),
                TappableForwardRow(
                    leftWidget: Text('Participate in a user test',
                        style: appTextTheme.headline4),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.participateUserTestPage)),
                // END HELP US IMPROVE
                SizedBox(height: 40.0),
                Text(
                  "Data management",
                  style: appTextTheme.headline1,
                ),
                SizedBox(height: 24.0),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'Rebuild metadata',
                      style: appTextTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'Clear local cache and re-download all artwork metadata.',
                        style: appTextTheme.bodyText1),
                    onTap: () => _showRebuildGalleryDialog()),
                addDivider(),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'Forget I exist',
                      style: appTextTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'Erase all information about me and delete my keys from my cloud backup including the keys on this device.',
                        style: appTextTheme.bodyText1),
                    onTap: () => _showForgetIExistDialog()),
                SizedBox(height: 56),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_packageInfo != null)
                        GestureDetector(
                            child: Text(
                              "Version ${_packageInfo!.version}(${_packageInfo!.buildNumber})",
                              style: appTextTheme.headline5,
                            ),
                            onTap: () async {
                              int now = DateTime.now().millisecondsSinceEpoch;
                              if (now - _lastTap < 1000) {
                                print("Consecutive tap");
                                _consecutiveTaps++;
                                print("taps = " + _consecutiveTaps.toString());
                                if (_consecutiveTaps == 3) {
                                  final newValue =
                                      await injector<ConfigurationService>()
                                          .toggleDemoArtworksMode();
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
                          child: Text("Release notes", style: linkStyle2)),
                      SizedBox(height: 10),
                      eulaAndPrivacyView(context),
                    ]),
                SizedBox(height: 60),
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

  // NOTE: Update this when support Social Recovery in Android
  Widget _socialRecoveryWidget() {
    if (!Platform.isIOS) return SizedBox();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40),
        Text(
          "Social Recovery",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 24),
        Text('Short description about social recovery',
            style: appTextTheme.bodyText1),
        SizedBox(height: 15),
        _setupSocialRecoveryWidget(),
        addOnlyDivider(),
        TappableForwardRow(
            leftWidget: Text('Helping Contacts', style: appTextTheme.headline4),
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.socialRecoveryHelpingsPage)),
      ],
    );
  }

  Widget _setupSocialRecoveryWidget() {
    return ValueListenableBuilder<SocialRecoveryStep?>(
        valueListenable: injector<SocialRecoveryService>().socialRecoveryStep,
        builder:
            (BuildContext context, SocialRecoveryStep? step, Widget? child) {
          if (step == null) return loadingIndicator(size: 16);

          switch (step) {
            case SocialRecoveryStep.SetupShardService:
              return TappableForwardRowWithContent(
                  leftWidget: Text(
                    'Setup Shard Service',
                    style: appTextTheme.headline4,
                  ),
                  bottomWidget: SizedBox(),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.setupShardServicePage));

            case SocialRecoveryStep.SetupEmergencyContact:
              return TappableForwardRowWithContent(
                  leftWidget: Text(
                    'Setup Emergency Contact',
                    style: appTextTheme.headline4,
                  ),
                  bottomWidget: SizedBox(),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.setupEmergencyContactPage));

            case SocialRecoveryStep.RestartWhenHasChanges:
              return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You has changed your accounts',
                        style: appTextTheme.bodyText1
                            ?.copyWith(color: AppColorTheme.errorColor)),
                    SizedBox(height: 15),
                    TappableForwardRowWithContent(
                        leftWidget: Text(
                          'Setup Shard Service',
                          style: appTextTheme.headline4,
                        ),
                        bottomWidget: SizedBox(),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.setupShardServicePage)),
                  ]);

            case SocialRecoveryStep.RestartWhenLostPlatform:
              return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Recommend to re-setup. Social Recovery is compromised because the platform shards have lost',
                        style: appTextTheme.bodyText1
                            ?.copyWith(color: AppColorTheme.errorColor)),
                    SizedBox(height: 15),
                    TappableForwardRowWithContent(
                        leftWidget: Text(
                          'Setup Shard Service',
                          style: appTextTheme.headline4,
                        ),
                        bottomWidget: SizedBox(),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.setupShardServicePage)),
                  ]);

            case SocialRecoveryStep.Done:
              return Column(
                children: [
                  Text(
                    "Social Recovery is completed",
                    style: appTextTheme.headline4,
                  ),
                  SizedBox(height: 15),
                ],
              );
          }
        });
  }

  Widget _settingItem(
      BuildContext context, String name, String value, Function() onTap) {
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: appTextTheme.headline4),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono"),
                ),
                SizedBox(width: 8.0),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            )
          ],
        ),
      ),
      onTap: onTap,
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
            return SizedBox();
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
            injector(),
            injector<NetworkConfigInjector>().mainnetInjector(),
            injector<NetworkConfigInjector>().testnetInjector(),
            injector()),
        child: ForgetExistView(),
      ),
      isDismissible: false,
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

        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
      },
      "CANCEL",
    );
  }
}
