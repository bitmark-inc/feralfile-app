import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (context, state) {
        final accounts = state.accounts;
        if (accounts == null) return SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Accounts",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 24),
            ...accounts
                .map((el) => Column(
                      children: [
                        _accountItem(context, el),
                        Divider(height: 32.0),
                      ],
                    ))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _accountItem(BuildContext context, Account account) {
    final persona = account.persona;
    if (persona != null) {
      return TappableForwardRow(
          leftWidget: Row(
            children: [
              Container(
                  width: 24,
                  height: 24,
                  child: Image.asset("assets/images/autonomyIcon.png")),
              SizedBox(width: 16),
              Text(
                  persona.name.isNotEmpty
                      ? persona.name
                      : account.accountNumber.mask(4),
                  style: appTextTheme.headline4),
            ],
          ),
          onTap: () {
            Navigator.of(context)
                .pushNamed(AppRouter.personaDetailsPage, arguments: persona);
          });
    }

    final connection = account.connections?.first;
    if (connection != null) {
      return TappableForwardRow(
          leftWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _appLogo(connection),
              SizedBox(width: 16),
              Text(
                  connection.name.isNotEmpty
                      ? connection.name
                      : connection.accountNumber.mask(4),
                  style: appTextTheme.headline4),
            ],
          ),
          rightWidget: Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Color(0x999999999), width: 1)),
            child: Text(
              "LINKED",
              style: TextStyle(
                  color: Color(0x999999999),
                  fontSize: 12,
                  fontFamily: "IBMPlexMono"),
            ),
          ),
          onTap: () {
            Navigator.of(context).pushNamed(AppRouter.linkedAccountDetailsPage,
                arguments: connection);
          });
    }

    return SizedBox();
  }

  Widget _appLogo(Connection connection) {
    switch (connection.connectionType) {
      case 'feralFileToken':
      case 'feralFileWeb3':
        return SvgPicture.asset("assets/images/feralfileAppIcon.svg");

      case 'walletConnect':
        final walletName =
            connection.wcConnectedSession?.sessionStore.remotePeerMeta.name;

        switch (walletName) {
          case "MetaMask":
            return Image.asset("assets/images/metamask-alternative.png");
          case "Trust Wallet":
            return Image.asset("assets/images/trust-alternative.png");
          default:
            return Image.asset("assets/images/walletconnect-alternative.png");
        }

      case 'walletBeacon':
        final walletName = connection.walletBeaconConnection?.peer.name;
        switch (walletName) {
          case "Kukai Wallet":
            return Image.asset("assets/images/kukai-wallet.png");
          default:
            return Image.asset("assets/images/tezos_wallet.png");
        }

      default:
        return SizedBox();
    }
  }
}
