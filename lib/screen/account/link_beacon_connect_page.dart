import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkBeaconConnectPage extends StatelessWidget {

  final String uri;

  const LinkBeaconConnectPage({Key? key, required this.uri}) : super(key: key);

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Scan code to link",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 24),
                    Container(
                      alignment: Alignment.center,
                      width: 180,
                      height: 180,
                      child: QrImage(
                        data: "tezos://$uri",
                        version: QrVersions.auto,
                        size: 180.0,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}