import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class BeOwnGalleryPage extends StatelessWidget {
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
                      "Be Your Own Gallery",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Autonomy is the home for all your digital art — a seamless, customizable way to enjoy your collection.",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "It is not possible to purchase NFTs in this app.",
                      style: appTextTheme.headline4,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE".toUpperCase(),
                    onPress: () {
                      Navigator.of(context).pushNamed(AppRouter.newAccountPage);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
