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
                      "VIEW YOUR DIGITAL ARTWORK COLLECTION ANYTIME, ANYWHERE.",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 30),
                    Text(
                      "At home, on vacation, on the train — never be without your digital art collection. Digital artworks you have purchased as NFTs on Ethereum, Feral File, or Tezos will automatically appear in your Autonomy.",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 15),
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
