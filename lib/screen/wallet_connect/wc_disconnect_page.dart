//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/wallet_connect.dart';

class WCDisconnectPage extends StatefulWidget {
  static const String tag = 'wc_disconnect';

  final WCClient client;

  const WCDisconnectPage({Key? key, required this.client}) : super(key: key);

  @override
  State<WCDisconnectPage> createState() => _WCDisconnectPageState();
}

class _WCDisconnectPageState extends State<WCDisconnectPage> {
  String address = "";

  @override
  void initState() {
    super.initState();

    _fetchAddress();
  }

  @override
  Widget build(BuildContext context) {
    final peerData = widget.client.remotePeerMeta;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              peerData?.name ?? "",
              style: theme.textTheme.headline1,
            ),
            const SizedBox(height: 40.0),
            Text(
              "Public address",
              style: theme.textTheme.headline4,
            ),
            const SizedBox(height: 16.0),
            Text(
              address,
              style: theme.textTheme.bodyText2,
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Disconnect".toUpperCase(),
                    onPress: () async {
                      if (widget.client.remotePeerMeta != null) {
                        injector<WalletConnectService>()
                            .disconnect(widget.client.remotePeerMeta!);
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

  Future _fetchAddress() async {
    // final ethAddress = await injector<NetworkConfigInjector>()
    //     .I<EthereumService>()
    //     .getETHAddress();
    // setState(() {
    //   address = ethAddress;
    // });
  }
}
