//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_connect/models/ethereum/wc_ethereum_transaction.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/web3dart.dart';

class WCSendTransactionPage extends StatefulWidget {
  static const String tag = 'wc_send_transaction';

  final WCSendTransactionPageArgs args;

  const WCSendTransactionPage({Key? key, required this.args}) : super(key: key);

  @override
  State<WCSendTransactionPage> createState() => _WCSendTransactionPageState();
}

class _WCSendTransactionPageState extends State<WCSendTransactionPage> {
  @override
  void initState() {
    super.initState();

    final to = EthereumAddress.fromHex(widget.args.transaction.to);
    final EtherAmount amount = EtherAmount.fromUnitAndValue(
        EtherUnit.wei, widget.args.transaction.value);

    context.read<WCSendTransactionBloc>().add(WCSendTransactionEstimateEvent(
        to, amount, widget.args.transaction.data, widget.args.uuid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          context.read<WCSendTransactionBloc>().add(
              WCSendTransactionRejectEvent(
                  widget.args.peerMeta, widget.args.id));
        },
      ),
      body: BlocBuilder<WCSendTransactionBloc, WCSendTransactionState>(
        builder: (context, state) {
          final EtherAmount amount = EtherAmount.fromUnitAndValue(
              EtherUnit.wei, widget.args.transaction.value);
          final total = state.fee != null ? state.fee! + amount.getInWei : null;
          return Stack(
            children: [
              Container(
                margin: EdgeInsets.only(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: MediaQuery.of(context).padding.bottom),
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
                              "Confirm",
                              style: theme.textTheme.headline1,
                            ),
                            const SizedBox(height: 40.0),
                            Text(
                              "Asset",
                              style: theme.textTheme.headline4,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              "Ethereum (ETH)",
                              style: theme.textTheme.bodyText2,
                            ),
                            const Divider(height: 32),
                            Text(
                              "From",
                              style: theme.textTheme.headline4,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              widget.args.transaction.from,
                              style: theme.textTheme.bodyText2,
                            ),
                            const Divider(height: 32),
                            Text(
                              "Connection",
                              style: theme.textTheme.headline4,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              widget.args.peerMeta.name,
                              style: theme.textTheme.bodyText2,
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Send",
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  "${EthAmountFormatter(amount.getInWei).format()} ETH",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Gas fee",
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  "${state.fee != null ? EthAmountFormatter(state.fee!).format() : "-"} ETH",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  "${total != null ? EthAmountFormatter(total).format() : "-"} ETH",
                                  style: theme.textTheme.headline4,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AuFilledButton(
                            text: "Send".toUpperCase(),
                            onPress: (state.fee != null && !state.isSending)
                                ? () async {
                                    final to = EthereumAddress.fromHex(
                                        widget.args.transaction.to);

                                    context.read<WCSendTransactionBloc>().add(
                                        WCSendTransactionSendEvent(
                                            widget.args.peerMeta,
                                            widget.args.id,
                                            to,
                                            amount.getInWei,
                                            state.fee!,
                                            widget.args.transaction.data,
                                            widget.args.uuid));
                                  }
                                : null,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              state.isSending
                  ? const Center(child: CupertinoActivityIndicator())
                  : const SizedBox(),
            ],
          );
        },
      ),
    );
  }
}

class WCSendTransactionPageArgs {
  final int id;
  final WCPeerMeta peerMeta;
  final WCEthereumTransaction transaction;
  final String uuid;

  WCSendTransactionPageArgs(
      this.id, this.peerMeta, this.transaction, this.uuid);
}
