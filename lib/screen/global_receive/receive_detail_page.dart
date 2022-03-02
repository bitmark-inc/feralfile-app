import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class GlobalReceiveDetailPage extends StatefulWidget {
  static const tag = "global_receive_detail";

  final Object? payload;

  const GlobalReceiveDetailPage({Key? key, required this.payload})
      : super(key: key);
  @override
  State<GlobalReceiveDetailPage> createState() =>
      _GlobalReceiveDetailPageState(payload as Account);
}

class _GlobalReceiveDetailPageState extends State<GlobalReceiveDetailPage> {
  final Account _account;
  bool _copied = false;

  _GlobalReceiveDetailPageState(this._account);

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
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            Text(
              "Receive NFT",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 96.0),
            Center(
              child: QrImage(
                data: _account.accountNumber,
                size: 180.0,
              ),
            ),
            SizedBox(height: 24.0),
            Text((_account.blockchain ?? "Unknown").toUpperCase(),
                style: appTextTheme.headline4),
            SizedBox(height: 18.0),
            accountItem(context, _account),
            SizedBox(height: 18.0),
            GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          width: 1.0, color: Color.fromRGBO(227, 227, 227, 1)),
                    ),
                    color: Color.fromRGBO(237, 237, 237, 0.3),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Account address",
                          textAlign: TextAlign.left,
                          style: appTextTheme.headline4,
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          _account.accountNumber,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                              fontSize: 12, fontFamily: "IBMPlexMono"),
                        )
                      ]),
                ),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: _account.accountNumber));
                  setState(() {
                    _copied = true;
                  });
                }),
            if (_copied) ...[
              SizedBox(height: 24),
              Center(child: Text("Copied", style: copiedTextStyle)),
            ],
            Spacer(),
            AuFilledButton(
                text: "SHARE",
                onPress: () => Share.share(_account.accountNumber,
                    subject: "My account number")),
            SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
