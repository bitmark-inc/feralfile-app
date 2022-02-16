import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
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
                    SizedBox(height: 30),
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
                    _bitmarkLinkView(context),
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
          height: 8,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                SvgPicture.asset("assets/images/feralfileAppIcon.svg"),
                Text("Feral File", style: appTextTheme.bodyText1),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.linkFeralFilePage);
            }),
      ],
    );
  }
}
