//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';

class TBSignMessagePage extends StatefulWidget {
  static const String tag = 'tb_sign_message';
  final BeaconRequest request;

  const TBSignMessagePage({Key? key, required this.request}) : super(key: key);

  @override
  State<TBSignMessagePage> createState() => _TBSignMessagePageState();
}

class _TBSignMessagePageState extends State<TBSignMessagePage> {
  WalletStorage? _currentPersona;

  @override
  void initState() {
    super.initState();
    fetchPersona();
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    final wallets = await Future.wait(
        personas.map((e) => LibAukDart.getWallet(e.uuid).getTezosWallet()));

    final currentWallet = wallets.firstWhere(
        (element) => element.address == widget.request.sourceAddress);
    final currentPersona =
        LibAukDart.getWallet(personas[wallets.indexOf(currentWallet)].uuid);
    setState(() {
      _currentPersona = currentPersona;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.request.payload!);
    final messageInUtf8 = utf8.decode(message, allowMalformed: true);

    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>().signResponse(widget.request.id, null);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
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
                      widget.request.appName ?? "",
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
                    onPress: _currentPersona != null
                        ? () async {
                            final wallet = await _currentPersona!.getTezosWallet();
                            final signature = await networkInjector
                                .I<TezosService>()
                                .signMessage(wallet, message);
                            injector<TezosBeaconService>()
                                .signResponse(widget.request.id, signature);
                            Navigator.of(context).pop();
                          }
                        : null,
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
