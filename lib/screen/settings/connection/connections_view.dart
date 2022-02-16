import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConnectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connections = injector<WalletConnectService>().wcClients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Connections",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 16.0),
        ...connections
            .map((el) => Column(
                  children: [
                    _connectionItem(context, el.remotePeerMeta?.name ?? "", "",
                        () {
                      Navigator.of(context)
                          .pushNamed(WCDisconnectPage.tag, arguments: el);
                    }),
                    Divider(height: 32.0),
                  ],
                ))
            .toList(),
        GestureDetector(
          onTap: () {
            Navigator.of(context)
                .pushNamed(ScanQRPage.tag, arguments: ScannerItem.GLOBAL);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Icon(Icons.add)],
          ),
        ),
      ],
    );
  }

  Widget _connectionItem(
      BuildContext context, String name, String value, Function() onTap) {
    return GestureDetector(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: appTextTheme.headline4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    fontFamily: "IBMPlexMono"),
              ),
              SizedBox(width: 8.0),
              Icon(CupertinoIcons.forward)
            ],
          )
        ],
      ),
      onTap: onTap,
    );
  }
}
