import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkWalletConnectPage extends StatefulWidget {
  final String unableOpenAppname;
  const LinkWalletConnectPage({Key? key, this.unableOpenAppname = ""})
      : super(key: key);

  @override
  State<LinkWalletConnectPage> createState() => _LinkWalletConnectPageState();
}

class _LinkWalletConnectPageState extends State<LinkWalletConnectPage> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();

    injector<WalletConnectDappService>().start();
    injector<WalletConnectDappService>().connect();
  }

  @override
  void dispose() {
    super.dispose();
    injector<WalletConnectDappService>().disconnect();
  }

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
                    if (widget.unableOpenAppname.isNotEmpty) ...[
                      Text(
                          "We were unable to open ${widget.unableOpenAppname} on this device.",
                          style: appTextTheme.bodyText1
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 24),
                    ],
                    Text(
                      "If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 24),
                    _wcQRCode(),
                    if (_copied) ...[
                      SizedBox(height: 24),
                      Center(child: Text("Copied", style: copiedTextStyle)),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wcQRCode() {
    return ValueListenableBuilder<String?>(
        valueListenable: injector<WalletConnectDappService>().wcURI,
        builder: (BuildContext context, String? wcURI, Widget? child) {
          return GestureDetector(
            child: Container(
              alignment: Alignment.center,
              width: 180,
              height: 180,
              child: wcURI != null
                  ? QrImage(
                      data: wcURI,
                      version: QrVersions.auto,
                      size: 180.0,
                    )
                  : CupertinoActivityIndicator(
                      // color: Colors.black,
                      ),
            ),
            onTap: () {
              Vibrate.feedback(FeedbackType.light);
              Clipboard.setData(ClipboardData(text: wcURI));
              setState(() {
                _copied = true;
              });
            },
          );
        });
  }
}
