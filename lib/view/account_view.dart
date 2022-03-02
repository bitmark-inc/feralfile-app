import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget accountWithConnectionItem(BuildContext context, Account account,
    {Function()? onTap}) {
  final persona = account.persona;
  if (persona != null) {
    return TappableForwardRow(
        leftWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                width: 24,
                height: 24,
                child: Image.asset("assets/images/autonomyIcon.png")),
            SizedBox(width: 16),
            Text(
                account.name.isNotEmpty
                    ? account.name
                    : account.accountNumber.mask(4),
                style: appTextTheme.headline4),
          ],
        ),
        onTap: onTap);
  }

  final connection = account.connections?.first;
  if (connection != null) {
    return TappableForwardRow(
        leftWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                alignment: Alignment.topCenter, child: _appLogo(connection)),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(connection.name.isNotEmpty ? connection.name : "Unnamed",
                    overflow: TextOverflow.ellipsis,
                    style: appTextTheme.headline4),
                SizedBox(height: 4),
                Text(
                  connection.accountNumber.mask(4),
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: "IBMPlexMono"),
                ),
              ],
            ),
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
        onTap: onTap);
  }

  return SizedBox();
}

Widget accountItem(BuildContext context, Account account,
    {Function()? onPersonaTap, Function()? onConnectionTap}) {
  final persona = account.persona;
  if (persona != null) {
    return TappableForwardRow(
        leftWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                width: 24,
                height: 24,
                child: Image.asset("assets/images/autonomyIcon.png")),
            SizedBox(width: 16),
            Text(
                account.name.isNotEmpty
                    ? account.name
                    : account.accountNumber.mask(4),
                style: appTextTheme.headline4),
          ],
        ),
        onTap: onPersonaTap);
  }

  final connection = account.connections?.first;
  if (connection != null) {
    return TappableForwardRow(
        leftWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
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
              border: Border.all(color: Color(0xFF6D6B6B), width: 1)),
          child: Text(
            "LINKED",
            style: TextStyle(
                color: Color(0xFF6D6B6B),
                fontSize: 12,
                fontFamily: "IBMPlexMono"),
          ),
        ),
        onTap: onConnectionTap);
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
          return Image.asset("assets/images/kukai_wallet.png");
        default:
          return Image.asset("assets/images/tezos_wallet.png");
      }

    default:
      return SizedBox();
  }
}
