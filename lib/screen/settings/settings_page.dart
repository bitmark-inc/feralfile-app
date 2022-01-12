import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_bloc.dart';
import 'package:autonomy_flutter/screen/settings/settings_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  static const String tag = 'settings';

  @override
  Widget build(BuildContext context) {
    context.read<SettingsBloc>().add(SettingsGetBalanceEvent());

    return Scaffold(
      body: BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
        return Container(
          margin:
          EdgeInsets.only(top: 64.0, left: 16.0, right: 16.0, bottom: 20.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cryptos",
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    SizedBox(height: 16.0),
                    _cryptoWidget(context, "Ethereum", state.ethBalance ?? "-- ETH", () {
                      Navigator.of(context).pushNamed(WalletDetailPage.tag, arguments: CryptoType.ETH);
                    }),
                    _cryptoWidget(context, "Tezos", state.xtzBalance ?? "-- XTZ", () {
                      Navigator.of(context).pushNamed(WalletDetailPage.tag, arguments: CryptoType.XTZ);
                    })
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _cryptoWidget(
      BuildContext context, String name, String value, Function() onTap) {
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: Theme.of(context).textTheme.headline5),
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
