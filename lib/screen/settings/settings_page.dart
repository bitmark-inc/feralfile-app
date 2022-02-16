import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/connection/connections_view.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_view.dart';
import 'package:autonomy_flutter/screen/settings/settings_bloc.dart';
import 'package:autonomy_flutter/screen/settings/settings_state.dart';
import 'package:autonomy_flutter/screen/settings/support/support_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  static const String tag = 'settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    context.read<SettingsBloc>().add(SettingsGetBalanceEvent());
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SettingsBloc>().add(SettingsGetBalanceEvent());
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context.read<SettingsBloc>().add(SettingsGetBalanceEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: GestureDetector(
                child: IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () {
                    Navigator.of(context).pushNamed(ScanQRPage.tag,
                        arguments: ScannerItem.GLOBAL);
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 32,
                  left: 16.0,
                  right: 16.0,
                  bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    child: Center(
                      child: Image.asset("assets/images/penrose.png"),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(height: 24.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConnectionView(),
                          SizedBox(height: 16.0),
                          Text(
                            "Cryptos",
                            style: appTextTheme.headline1,
                          ),
                          SizedBox(height: 16.0),
                          _settingItem(
                              context, "Ethereum", state.ethBalance ?? "-- ETH",
                              () {
                            Navigator.of(context).pushNamed(
                                WalletDetailPage.tag,
                                arguments: CryptoType.ETH);
                          }),
                          _settingItem(
                              context, "Tezos", state.xtzBalance ?? "-- XTZ",
                              () {
                            Navigator.of(context).pushNamed(
                                WalletDetailPage.tag,
                                arguments: CryptoType.XTZ);
                          }),
                          SizedBox(height: 24.0),
                          BlocProvider(
                            create: (_) => PreferencesBloc(injector()),
                            child: PreferenceView(),
                          ),
                          SizedBox(height: 24.0),
                          Text(
                            "Networks",
                            style: appTextTheme.headline1,
                          ),
                          SizedBox(height: 16.0),
                          _settingItem(
                              context,
                              "Select network",
                              state.network == Network.TESTNET
                                  ? "Test network"
                                  : "Main network", () async {
                            await Navigator.of(context)
                                .pushNamed(SelectNetworkPage.tag);
                            if (injector<ConfigurationService>().getNetwork() !=
                                state.network) {
                              Navigator.of(context).pop();
                            }
                          }),
                          SizedBox(height: 40),
                          SupportView(),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      }),
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
}
