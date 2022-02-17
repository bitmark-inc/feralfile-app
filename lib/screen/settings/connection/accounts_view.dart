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
    Widget icon;
    switch (account.type) {
      case ConnectionType.feralFileWeb3:
        icon = SvgPicture.asset("assets/images/feralfileAppIcon.svg");
        break;
      case ConnectionType.walletBeacon:
        icon = Image.asset("assets/images/tezos_wallet.png");
        break;
      default:
        icon = Image.asset("assets/images/autonomyIcon.png");
        break;
    }
    if (connection != null) {
      return TappableForwardRow(
          leftWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
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
}
