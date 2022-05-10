import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
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
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
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
  int _lastTap = 0;
  int _consecutiveTaps = 0;
  var _forceAccountsViewRedraw;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _loadPackageInfo();
    context.read<AccountsBloc>().add(GetAccountsEvent());
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
    WidgetsBinding.instance?.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context.read<AccountsBloc>().add(GetAccountsEvent());
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
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 15),
            controller: _controller,
            children: [
              SizedBox(height: 160),
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
                  Row(
                    children: [
                      Expanded(
                        child: AuOutlinedButton(
                          text: "RECEIVE".toUpperCase(),
                          onPress: () => Navigator.of(context)
                              .pushNamed(AppRouter.globalReceivePage),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
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
                      child: Text('+ Add',
                          style: appTextTheme.bodyText2
                              ?.copyWith(color: Colors.black))),
                  SizedBox(width: 13),
                ],
              ),
              SizedBox(height: 40),
              BlocProvider(
                create: (_) => PreferencesBloc(
                    injector(), injector<NetworkConfigInjector>().I()),
                child: PreferenceView(),
              ),
              SizedBox(height: 40.0),
              BlocProvider(
                create: (_) => UpgradesBloc(injector(), injector()),
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
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRouter.bugBountyPage)),
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
                      'Erase all information about me and delete my keys from my cloud backup.',
                      style: appTextTheme.bodyText1),
                  onTap: () => _showForgetIExistDialog()),
              SizedBox(height: 56),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                            await UIHelper.showInfoDialog(context, "Demo mode",
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
                    child: Text("Release notes", style: linkStyle)),
                SizedBox(height: 10),
                eulaAndPrivacyView(),
              ]),
              SizedBox(height: 60),
            ],
          ),
          PenroseTopBarView(false, _controller),
        ],
      )),
    );
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
