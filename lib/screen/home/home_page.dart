import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/view/filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin:
            EdgeInsets.only(top: 64.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset("assets/images/penrose.png"),
            ),
            SizedBox(height: 24.0),
            Text(
              "Gallery",
              style: Theme.of(context).textTheme.headline1,
            ),
            SizedBox(height: 24.0),
            Text(
              "Your gallery is empty for now.",
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Expanded(child: SizedBox()),
            FilledButton(
              text: "Help us find your collection".toUpperCase(),
              onPress: () async {
                dynamic uri =
                    await Navigator.of(context).pushNamed(ScanQRPage.tag);
                if (uri != null && uri is String && uri.startsWith("wc:")) {
                  injector<WalletConnectService>().connect(uri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
