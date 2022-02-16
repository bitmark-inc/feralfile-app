import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/crypto.dart';

class WCSignMessagePage extends StatelessWidget {
  static const String tag = 'wc_sign_message';

  final WCSignMessagePageArgs args;

  const WCSignMessagePage({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(args.message);
    final messageInUtf8 = utf8.decode(message, allowMalformed: true);

    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>()
              .rejectRequest(args.peerMeta, args.id);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.0),
                    Text(
                      "Confirm",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 40.0),
                    Text(
                      "Connection",
                      style: appTextTheme.headline4,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      args.peerMeta.name,
                      style: appTextTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Message",
                      style: appTextTheme.headline4,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: appTextTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Sign".toUpperCase(),
                    onPress: () async {
                      final signature = await networkInjector
                          .I<EthereumService>()
                          .signPersonalMessage(message);
                      injector<WalletConnectService>()
                          .approveRequest(args.peerMeta, args.id, signature);

                      if (args.peerMeta.url.contains("feralfile")) {
                        Future.delayed(const Duration(milliseconds: 3000), () {
                          networkInjector.I<FeralFileService>().saveAccount();
                        });
                      }

                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WCSignMessagePageArgs {
  final int id;
  final WCPeerMeta peerMeta;
  final String message;

  WCSignMessagePageArgs(this.id, this.peerMeta, this.message);
}
