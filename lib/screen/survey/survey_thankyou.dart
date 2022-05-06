import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class SurveyThankyouPage extends StatelessWidget {
  static const String tag = 'survey_thankyou';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Thank you!",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 40.0),
            Text(
                "You’ve been automatically entered in this month’s drawing to win a Feral File artwork. If you win, we’ll transfer the NFT to your Autonomy account and notify you.",
                style: appTextTheme.bodyText1),
            Spacer(),
            AuFilledButton(
                text: "Continue",
                onPress: () => Navigator.of(context).popUntil((route) =>
                    route.settings.name == AppRouter.homePage ||
                    route.settings.name == AppRouter.homePageNoTransition)),
            SizedBox(height: 27.0),
          ],
        ),
      ),
    );
  }
}
