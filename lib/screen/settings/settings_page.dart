import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_view.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/screen/settings/support/support_view.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:autonomy_flutter/view/penrose_scrolling_container.dart';
import 'package:flutter/cupertino.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _loadPackageInfo();
    context.read<AccountsBloc>().add(GetAccountsEvent());
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
  }

  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      body: PenroseScrollingContainer(
        page: AppRouter.settingsPage,
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  SizedBox(height: 10),
                  AccountsView(),
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
                create: (_) => PreferencesBloc(injector()),
                child: PreferenceView(),
              ),
              SizedBox(height: 40.0),
              BlocProvider(
                create: (_) => UpgradesBloc(networkInjector.I(), injector()),
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
              SizedBox(height: 40),
              SupportView(),
              SizedBox(height: 56),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (_packageInfo != null)
                  Text(
                    "Version ${_packageInfo!.version}(${_packageInfo!.buildNumber})",
                    style: appTextTheme.headline5,
                  ),
                SizedBox(height: 5),
                eulaAndPrivacyView(),
              ]),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
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
                Icon(CupertinoIcons.forward)
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
}
