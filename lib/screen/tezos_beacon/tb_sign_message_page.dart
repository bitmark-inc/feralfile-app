import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/crypto.dart';

class TBSignMessagePage extends StatelessWidget {
  static const String tag = 'tb_sign_message';

  final BeaconRequest request;

  const TBSignMessagePage({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(request.payload!);
    final messageInUtf8 = utf8.decode(message, allowMalformed: true);

    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>().signResponse(request.id, null);
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
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    SizedBox(height: 40.0),
                    Text(
                      "Connection",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      request.appName ?? "",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Message",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: Theme.of(context).textTheme.bodyText2,
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
                      injector<TezosBeaconService>()
                          .signResponse(request.id, signature);
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
