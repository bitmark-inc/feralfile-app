import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LinkAccountPage extends StatelessWidget {
  const LinkAccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link account",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    RichText(
                      text: TextSpan(
                        style: appTextTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(
                              text:
                                  'Linking your account to Autonomy does not import or access your private keys.',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text:
                                ' If you have multiple accounts in your wallet, make sure that the account you want to link is active. ',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    _bitmarkLinkView(context),
                    SizedBox(height: 24),
                    _ethereumLinkView(context),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bitmarkLinkView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BITMARK",
          style: appTextTheme.headline4,
        ),
        SizedBox(
          height: 16,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                SvgPicture.asset("assets/images/feralfileAppIcon.svg"),
                SizedBox(width: 16),
                Text("Feral File", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.linkFeralFilePage);
            }),
      ],
    );
  }

  Widget _ethereumLinkView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ETHEREUM",
          style: appTextTheme.headline4,
        ),
        SizedBox(
          height: 20,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/metamask-alternative.png"),
                SizedBox(width: 16),
                Text("MetaMask", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.linkFeralFilePage);
            }),
        SizedBox(width: 16),
        Divider(),
        SizedBox(width: 16),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/walletconnect-alternative.png"),
                SizedBox(width: 16),
                Text("Other  Ethereum wallets", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.linkWalletConnectPage);
            }),
      ],
    );
  }
}
