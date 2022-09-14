//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
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

    final currentWallet = wallets.firstWhereOrNull(
        (element) => element.address == widget.request.sourceAddress);

    if (currentWallet == null) {
      injector<TezosBeaconService>().signResponse(widget.request.id, null);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final currentPersona =
        LibAukDart.getWallet(personas[wallets.indexOf(currentWallet)].uuid);
    setState(() {
      _currentPersona = currentPersona;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.request.payload!);
    final Uint8List viewMessage = message.length > 6 &&
            message.sublist(0, 2).equals(Uint8List.fromList([5, 1]))
        ? message.sublist(6)
        : message;
    final messageInUtf8 = utf8.decode(viewMessage, allowMalformed: true);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>().signResponse(widget.request.id, null);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),
                    Text(
                      "h_confirm".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    const SizedBox(height: 40.0),
                    Text(
                      "connection".tr(),
                      style: theme.textTheme.headline4,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.request.appName ?? "",
                      style: theme.textTheme.bodyText2,
                    ),
                    const Divider(height: 32),
                    Text(
                      "message".tr(),
                      style: theme.textTheme.headline4,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: theme.textTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "sign".tr().toUpperCase(),
                    onPress: _currentPersona != null
                        ? () => withDebounce(() async {
                              final wallet =
                                  await _currentPersona!.getTezosWallet();
                              final signature = await injector<TezosService>()
                                  .signMessage(wallet, message);
                              injector<TezosBeaconService>()
                                  .signResponse(widget.request.id, signature);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            })
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
