import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class LinkTezosKukaiPage extends StatelessWidget {
  const LinkTezosKukaiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();

    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Linking to Kukai",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "Since Kukai only exists as a web wallet, you will need to follow these additional steps to link it to Autonomy: ",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 20),
                    _stepWidget('1',
                        'Generate a link request and send it to the web browser where you are currently signed in to Kukai.'),
                    SizedBox(height: 10),
                    _stepWidget('2',
                        'When prompted by Kukai, approve Autonomy’s permissions requests. '),
                    SizedBox(height: 40),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(child: _wantMoreSecurityWidget())]),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "GENERATE LINK".toUpperCase(),
                    onPress: () async {
                      final uri = await tezosBeaconService.getConnectionURI();
                      Share.share("https://wallet.kukai.app/tezos$uri");
                    },
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(String stepNumber, String stepGuide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: appTextTheme.caption,
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: appTextTheme.bodyText1),
        )
      ],
    );
  }

  Widget _wantMoreSecurityWidget() {
    return Container(
      padding: EdgeInsets.all(10),
      color: AppColorTheme.secondaryDimGreyBackground,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Want more security and portability?',
                style: TextStyle(
                    color: AppColorTheme.secondaryDimGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "AtlasGrotesk",
                    height: 1.377)),
            SizedBox(height: 5),
            Text(
                'You can get all the Tezos functionality of Kukai in a mobile app by importing your account to Autonomy.',
                style: bodySmall),
            SizedBox(height: 10),
            Text('Learn more about Autonomy security ...', style: linkStyle),
          ]),
    );
  }
}
